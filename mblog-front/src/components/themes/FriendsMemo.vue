<template>
  <div class="friend-memo bg-white dark:bg-[#171717] rounded-lg shadow-sm mb-3 p-3">
    <div class="flex">
      <!-- 头像 -->
      <img :src="avatarUrl" class="w-10 h-10 rounded-full object-cover flex-shrink-0 select-none" alt="avatar" />

      <div class="flex-1 ml-2.5 min-w-0">
        <!-- 昵称 -->
        <div class="text-[#576b95] font-bold text-[15px] leading-5 cursor-default truncate">
          {{ props.memo.authorName || '游客' }}
        </div>

        <!-- 内容 -->
        <div
          class="friend-md md-content text-[15px] text-gray-800 dark:text-gray-300 leading-6 mt-1 break-words"
          :class="{ 'line-clamp-6': folded }"
          ref="contentEl"
          v-html="props.memo && props.memo.content && marked.parse(props.memo.content)"
        ></div>
        <div
          class="text-[#576b95] text-sm mt-1 cursor-pointer select-none"
          v-if="needFold && folded"
          @click="folded = false"
        >
          全文
        </div>
        <div
          class="text-[#576b95] text-sm mt-1 cursor-pointer select-none"
          v-if="needFold && !folded"
          @click="folded = true"
        >
          收起
        </div>

        <!-- 图片九宫格 -->
        <div class="mt-2">
          <n-image-group>
            <div
              v-if="imgs.length === 1"
              class="single-img"
              @click.stop
            >
              <n-image
                :src="imgSrc(imgs[0])"
                :fallback-src="imgs[0].url"
                :preview-src="imgSrc(imgs[0])"
                object-fit="cover"
                class="rd"
              >
                <template #placeholder>
                  <div class="loading-ph">加载中...</div>
                </template>
              </n-image>
            </div>
            <div v-else-if="imgs.length > 1" class="grid-imgs" @click.stop>
              <n-image
                v-for="(img, index) in imgs"
                :key="index"
                :src="imgSrc(img)"
                :fallback-src="img.url"
                :preview-src="imgSrc(img)"
                object-fit="cover"
                class="rd overflow-hidden"
              >
                <template #placeholder>
                  <div class="loading-ph">加载中...</div>
                </template>
              </n-image>
            </div>
          </n-image-group>
        </div>

        <!-- 时间 + 来源 + 操作 -->
        <div class="flex items-center justify-between mt-2 text-xs text-gray-400 dark:text-gray-500">
          <div class="flex items-center gap-2 min-w-0">
            <span class="ws-nowrap">{{ dayjs(props.memo.created).locale('zh-cn').fromNow().replaceAll(/\s+/g, '') }}</span>
            <span v-if="props.memo.source && props.memo.source !== 'web'" class="ws-nowrap">· {{ props.memo.source }}</span>
            <span v-if="props.memo.priority > 0" class="text-orange-400 ws-nowrap">· 置顶</span>
          </div>
          <div class="flex items-center gap-1 flex-shrink-0">
            <!-- 赞 -->
            <div
              class="op-btn"
              :class="{ 'liked': props.memo.liked > 0 }"
              :title="props.memo.liked > 0 ? '取消赞' : '赞'"
              @click="toggleLike"
            >
              <div class="i-carbon:favorite-filled text-red-500" v-if="props.memo.liked > 0"></div>
              <div class="i-carbon:favorite" v-else></div>
              <span v-if="props.memo.likeCount > 0">{{ props.memo.likeCount }}</span>
            </div>
            <!-- 评论 -->
            <div class="op-btn" :class="{ 'active': showCommentInput }" title="评论" @click="toggleComment">
              <div class="i-carbon:chat"></div>
              <span v-if="props.memo.commentCount > 0">{{ props.memo.commentCount }}</span>
            </div>
            <!-- 删除(作者本人或管理员) -->
            <div class="op-btn hover:text-red-500" title="删除" v-if="canDelete">
              <n-popconfirm :show-icon="false" @positive-click="removeMemo" negative-text="取消" positive-text="删除">
                <template #trigger>
                  <div class="i-carbon:trash-can"></div>
                </template>
                确定删除这条动态吗?
              </n-popconfirm>
            </div>
          </div>
        </div>

        <!-- 点赞 + 评论面板 -->
        <div
          class="interact mt-2 rounded-md bg-[#f7f7f7] dark:bg-[#262626] px-2.5 py-1.5"
          v-if="showInteract"
        >
          <!-- 点赞行 -->
          <div class="flex items-center gap-1.5 text-[13px] py-1 border-b border-black/5 dark:border-white/10" v-if="props.memo.likeCount > 0">
            <div class="i-carbon:favorite-filled text-red-500 text-sm"></div>
            <span class="text-gray-600 dark:text-gray-400">
              {{ props.memo.likeCount }}人觉得很赞
            </span>
          </div>

          <!-- 评论列表 -->
          <div class="text-[13px]" v-if="commentResp.list && commentResp.list.length > 0">
            <div class="comment-item" v-for="(comment, index) in commentResp.list" :key="comment.id">
              <div class="flex items-start py-1">
                <div class="min-w-0 flex-1 leading-5">
                  <span class="text-[#576b95] font-semibold cursor-pointer ws-nowrap">{{ comment.userName }}</span>
                  <span v-if="comment.mentioned" class="text-[#576b95] ws-nowrap"> 回复 @{{ comment.mentioned }}:</span>
                  <span v-else>:</span>
                  <span class="text-gray-700 dark:text-gray-300 break-all cursor-pointer" @click="toggleReply(index)">
                    {{ comment.content }}
                  </span>
                </div>
                <div
                  class="text-gray-300 dark:text-gray-600 hover:text-red-500 cursor-pointer flex-shrink-0 ml-1"
                  v-if="userinfo.token && (comment.userId === userinfo.userId || userinfo.role === 'ADMIN')"
                  title="删除评论"
                  @click.stop="removeComment(comment.id)"
                >
                  <div class="i-carbon:close text-xs mt-1.5"></div>
                </div>
              </div>
              <!-- 回复输入 -->
              <div class="pb-1" v-if="showReplyArray[index]">
                <FriendsCommentInput :memoId="props.memo.id" :commentId="comment.id" :reply="comment.userName" />
              </div>
            </div>
          </div>

          <!-- 评论输入 -->
          <div class="py-1" v-if="showCommentInput">
            <FriendsCommentInput :memoId="props.memo.id" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { MemoDTO } from '@/types/memo';
import type { CommentDTO, QueryCommentResponse } from '@/types/comment';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import 'dayjs/locale/zh-cn';
import { marked } from 'marked'
import { mangle } from 'marked-mangle'
import { gfmHeadingId } from 'marked-gfm-heading-id'

dayjs.extend(relativeTime)

const options = { prefix: 'mblog-' }
marked.use(gfmHeadingId(options))
marked.use(mangle())

const props = withDefaults(
  defineProps<{ memo: MemoDTO }>(),
  {}
)

const userinfo = useStorage('userinfo', { token: '', userId: 0, role: '' })

// 头像:优先当前用户头像,否则首字母占位
const avatarUrl = computed(() => {
  if (userinfo.value.avatarUrl) return userinfo.value.avatarUrl
  const name = (props.memo.authorName || '微').slice(0, 1)
  return (
    'data:image/svg+xml,' +
    encodeURIComponent(
      `<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80"><rect width="80" height="80" rx="40" fill="#07c160"/><text x="40" y="52" font-size="36" text-anchor="middle" fill="#fff" font-family="sans-serif">${name}</text></svg>`
    )
  )
})

const imgs = computed(() => {
  return props.memo.resources?.filter((r) => r.fileType.includes('image')) || []
})

// 本地图片补充域名
const imgSrc = (img: any) => {
  return img.url + (img.fileType.includes('webp') ? '' : img.suffix || '')
}

/* ---------------- 内容折叠 ---------------- */
const contentEl = ref<HTMLElement | null>(null)
const folded = ref(false)
const needFold = ref(false)
const { height } = useElementSize(contentEl)

watch(height, (h) => {
  if (h > 132 && !needFold.value) {
    needFold.value = true
    folded.value = true
  }
})

/* ---------------- 评论 ---------------- */
const commentResp: Ref<QueryCommentResponse> = ref({} as QueryCommentResponse)
const showCommentInput = ref(false)
const showReplyArray = ref<Array<boolean>>([])

const showInteract = computed(() => {
  return (
    showCommentInput.value ||
    props.memo.likeCount > 0 ||
    (commentResp.list && commentResp.list.length > 0)
  )
})

const toggleComment = () => {
  showCommentInput.value = !showCommentInput.value
  if (showCommentInput.value && !commentResp.list) {
    loadComments()
  }
}

const toggleReply = (index: number) => {
  const current = showReplyArray.value[index]
  showReplyArray.value = []
  showReplyArray.value[index] = !current
}

const loadComments = async () => {
  const { data, error } = await useMyFetch('/api/comment/query')
    .post({ page: 1, size: 100, memoId: props.memo.id })
    .json()
  if (error.value) {
    // 开发模式:无后端时展示 mock 评论
    if (import.meta.env.DEV) {
      commentResp.value = { total: 2, totalPage: 1, list: buildMockComments() } as QueryCommentResponse
      showReplyArray.value = commentResp.value.list.map(() => false)
    }
    return
  }
  commentResp.value = data.value
  showReplyArray.value = commentResp.value.list?.map(() => false) || []
}

// 开发模式 mock 评论
function buildMockComments(): Array<CommentDTO> {
  return [
    {
      id: 1,
      userId: 2,
      content: '这也太美了吧,下次带上我!',
      mentioned: '',
      mentionedUserId: '',
      memoId: props.memo.id,
      userName: '小美',
      created: new Date(),
      updated: new Date(),
      email: '',
      link: '',
      approved: 1,
    },
    {
      id: 2,
      userId: 3,
      content: '安排!周末走起~',
      mentioned: '小美',
      mentionedUserId: '2',
      memoId: props.memo.id,
      userName: '老王',
      created: new Date(),
      updated: new Date(),
      email: '',
      link: '',
      approved: 1,
    },
  ]
}

const removeComment = async (id: number) => {
  const { message } = createDiscreteApi(['message'])
  const { error } = await useMyFetch(`/api/comment/remove?id=${id}`).post().json()
  if (!error.value) {
    message.success('删除成功')
    await loadComments()
    props.memo.commentCount = Math.max(0, props.memo.commentCount - 1)
  }
}

/* ---------------- 删除 ---------------- */
// 作者本人或管理员可以删除
const canDelete = computed(() => {
  if (!userinfo.value.token) return false
  return userinfo.value.role === 'ADMIN' || props.memo.userId === userinfo.value.userId
})

const removeMemo = async () => {
  const { message } = createDiscreteApi(['message'])
  const { error } = await useMyFetch(`/api/memo/remove?id=${props.memo.id}`).post().json()
  if (!error.value) {
    message.success('删除成功')
    changedMemoBus.emit({ id: props.memo.id, deleteMemo: true })
  }
}

/* ---------------- 点赞 ---------------- */
const toggleLike = async () => {
  const { message } = createDiscreteApi(['message'])
  if (!userinfo.value.token) {
    message.warning('请先登录')
    return
  }
  const { error } = await useMyFetch('/api/memo/relation')
    .post({
      memoId: props.memo.id,
      type: 'LIKE',
      operateType: props.memo.liked > 0 ? 'REMOVE' : 'ADD',
    })
    .json()
  if (!error.value) {
    props.memo.liked = props.memo.liked > 0 ? 0 : 1
    props.memo.likeCount += props.memo.liked > 0 ? 1 : -1
  }
}

/* ---------------- 事件 ---------------- */
// 评论保存后刷新评论列表
commetSavedBus.on(async () => {
  await loadComments()
  const { data, error } = await useMyFetch('/api/memo/' + props.memo.id).post().json()
  if (!error.value) {
    props.memo.commentCount = data.value.commentCount
  }
})

onMounted(async () => {
  await loadComments()
})
</script>

<style scoped lang="scss">
.friend-memo {
  transition: box-shadow 0.2s;

  &:hover {
    box-shadow: 0 2px 12px rgba(0, 0, 0, 0.08);
  }
}

.friend-md > p {
  margin: 0;
}

/* 单图:原比例大图 */
.single-img {
  width: fit-content;
  max-width: 100%;

  :deep(img) {
    max-width: 100%;
    max-height: 240px;
    width: auto;
    border-radius: 6px;
    cursor: zoom-in;
  }
}

/* 多图:3列九宫格 */
.grid-imgs {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 4px;
  width: 100%;

  :deep(.n-image) {
    width: 100%;
    aspect-ratio: 1;
    border-radius: 4px;
    overflow: hidden;
    cursor: zoom-in;

    img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      display: block;
    }
  }
}

.loading-ph {
  width: 100%;
  height: 100%;
  min-height: 80px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #0001;
  font-size: 12px;
  color: #999;
}

/* 操作按钮 */
.op-btn {
  display: flex;
  align-items: center;
  gap: 2px;
  padding: 3px 8px;
  border-radius: 6px;
  cursor: pointer;
  color: #999;
  transition: all 0.15s;

  &:hover {
    background: rgba(0, 0, 0, 0.05);
    color: #576b95;
  }

  &.active {
    color: #576b95;
    background: rgba(0, 0, 0, 0.05);
  }

  &.liked {
    color: #e64340;
  }
}

.comment-item {
  &:hover {
    background: rgba(0, 0, 0, 0.03);
  }
}
</style>
