<route lang="yaml">
  meta:
    layout: friends
</route>
<template>
  <div class="friends-page">
    <!-- 顶部封面:微信朋友圈风格头部 -->
    <header class="cover relative overflow-hidden">
      <img class="cover-img w-full h-[280px] object-cover" :src="coverUrl" @error="onCoverError" alt="" />
      <div class="cover-mask absolute inset-0 bg-gradient-to-t from-black/60 via-black/20 to-black/10"></div>
      <div class="absolute right-4 bottom-4 flex items-end gap-3">
        <div class="pb-1">
          <div class="text-white text-xl font-bold drop-shadow text-right">{{ displayName }}</div>
          <div class="text-white/80 text-xs text-right mt-1">{{ bio || '分享生活,记录美好' }}</div>
        </div>
        <img :src="avatarUrl" class="w-16 h-16 rounded-lg border-2 border-white/90 object-cover shadow" @error="user.avatarUrl = ''" alt="avatar" />
      </div>
      <!-- 主题切换 + 发布 + 管理 -->
      <div class="absolute left-4 top-4 flex items-center gap-2">
        <div
          class="bg-white/20 hover:bg-white/30 backdrop-blur text-white text-sm px-4 py-1.5 rounded-full cursor-pointer flex items-center gap-1 transition"
          :title="isDark ? '切换亮色模式' : '切换暗色模式'"
          @click="toggleTheme"
        >
          <div class="i-carbon:moon text-base" v-if="!isDark"></div>
          <div class="i-carbon:sun text-base" v-else></div>
          <span>{{ isDark ? '日间' : '夜间' }}</span>
        </div>
        <div
          class="bg-white/20 hover:bg-white/30 backdrop-blur text-white text-sm px-4 py-1.5 rounded-full cursor-pointer flex items-center gap-1 transition"
          v-if="userinfo.token"
          @click="showInput = !showInput"
        >
          <div class="i-carbon:camera text-base"></div>
          <span>{{ showInput ? '收起' : '发布' }}</span>
        </div>
        <!-- 后台管理入口 -->
        <div
          class="bg-white/20 hover:bg-white/30 backdrop-blur text-white text-sm px-4 py-1.5 rounded-full cursor-pointer flex items-center gap-1 transition"
          v-if="userinfo.token"
          @click="goSettings"
        >
          <div class="i-carbon:settings text-base"></div>
          <span>管理</span>
        </div>
      </div>
    </header>

    <!-- 发布输入 -->
    <div v-if="showInput" class="px-3 pt-3">
      <FriendsMemoInput />
    </div>

    <!-- 时间线主体 -->
    <main class="px-3 py-4">
      <template v-for="group in groupedMemos" :key="group.dateKey">
        <!-- 日期分组(今天/昨天/日期) -->
        <div class="timeline-date">
          <span class="dot"></span>
          <span class="label">{{ group.label }}</span>
        </div>
        <div class="timeline-items">
          <FriendsMemo v-for="memo in group.items" :key="memo.id" :memo="memo" />
        </div>
      </template>

      <div v-if="state.memos.length === 0" class="text-center text-gray-400 text-sm py-16">
        <div class="i-carbon:face-satisfied text-4xl mx-auto mb-3 opacity-60"></div>
        还没有动态,点击右上角发布第一条吧
      </div>

      <div
        v-if="state.search.page < state.totalPage"
        class="text-center text-gray-500 text-sm py-6 cursor-pointer hover:text-blue-500 select-none"
        @click="++state.search.page"
      >
        点击查看更多...
      </div>
      <div v-else-if="state.memos.length > 0" class="text-center text-gray-400 text-xs py-6">
        — 没有更多了 —
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { useMyFetch } from '@/api/fetch';
import type { ListMemoResponse, MemoDTO, MemoSearchParam } from '@/types/memo';
import type { User } from '@/types/user';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import 'dayjs/locale/zh-cn';
import { onMounted, reactive, computed } from 'vue';

dayjs.extend(relativeTime)

const userinfo = useStorage('userinfo', { token: '', userId: 0 })
const router = useRouter()
const goSettings = () => {
  router.push('/settings')
}

// 封面图:优先本地缓存(mblog_banner_url) → 后台配置 BANNER_URL → 默认图
const DEFAULT_COVER =
  'https://images.unsplash.com/photo-1711299253442-de19d4dacaae?q=80&w=3500&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D'
const cachedBanner = useStorage('mblog_banner_url', '')
const coverUrl = ref(cachedBanner.value || DEFAULT_COVER)

// 封面图加载失败时回退默认图
const onCoverError = () => {
  if (coverUrl.value !== DEFAULT_COVER) {
    coverUrl.value = DEFAULT_COVER
    cachedBanner.value = ''
  }
}

interface State {
  memos: Array<MemoDTO>
  search: MemoSearchParam
  total: number
  totalPage: number
}

const state: State = reactive({
  memos: [],
  search: {
    page: 1,
    size: 20,
    begin: dayjs().subtract(20, 'year').startOf('d').toDate(),
    end: dayjs().endOf('d').toDate(),
  },
  total: 0,
  totalPage: 0,
})

// 初始直接读本地 userinfo 缓存,避免刷新时先用占位再切换导致闪烁
let user = ref<Partial<User>>(
  userinfo.value.avatarUrl || userinfo.value.displayName
    ? {
        avatarUrl: userinfo.value.avatarUrl,
        displayName: userinfo.value.displayName,
        bio: userinfo.value.bio,
      }
    : {}
)
const showInput = ref(false)
const themeModelVal = useLocalStorage('themeModel', { theme: 'light' })
const isDark = computed(() => themeModelVal.value.theme === 'dark')
const toggleTheme = () => {
  themeModelVal.value.theme = isDark.value ? 'light' : 'dark'
  themeChangeBus.emit({ theme: themeModelVal.value.theme })
}

const displayName = computed(() => user.value.displayName || '朋友圈')
const avatarUrl = computed(
  () => user.value.avatarUrl || 'data:image/svg+xml,' + encodeURIComponent(avatarSvg(displayName.value))
)
const bio = computed(() => user.value.bio)

// 无头像时的占位头像
function avatarSvg(name: string) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80"><rect width="80" height="80" rx="8" fill="#07c160"/><text x="40" y="52" font-size="36" text-anchor="middle" fill="#fff" font-family="sans-serif">${(
    name || '微'
  ).slice(0, 1)}</text></svg>`
}

// 按天分组,微信朋友圈时间线
const groupedMemos = computed(() => {
  const groups: Array<{ dateKey: string; label: string; items: Array<MemoDTO> }> = []
  for (const memo of state.memos) {
    const d = dayjs(memo.created)
    const key = d.format('YYYY-MM-DD')
    let group = groups.find((g) => g.dateKey === key)
    if (!group) {
      let label = d.format('YYYY年M月D日')
      if (d.isSame(dayjs(), 'day')) label = '今天'
      else if (d.isSame(dayjs().subtract(1, 'day'), 'day')) label = '昨天'
      group = { dateKey: key, label, items: [] }
      groups.push(group)
    }
    group.items.push(memo)
  }
  return groups
})

onMounted(async () => {
  await reload()

  const { data, error } = await useMyFetch('/api/user/current').post().json()
  if (!error.value) {
    user.value = data.value
    // 同步写回本地缓存,刷新时直接读取
    userinfo.value = Object.assign(userinfo.value, data.value)
  }

  // 读取后台配置的封面图,并写入本地缓存
  const { data: cfg, error: cfgErr } = await useMyFetch('/api/sysConfig/').get().json()
  if (!cfgErr.value) {
    const configData = cfg.value as Array<{ key: string; value: string }>
    const banner = configData.find((r) => r.key === 'BANNER_URL')?.value
    if (banner) {
      coverUrl.value = banner
      cachedBanner.value = banner
    } else {
      coverUrl.value = DEFAULT_COVER
      cachedBanner.value = ''
    }
  }
})

const reload = async () => {
  // 开发模式:无后端时用 mock 数据预览朋友圈效果
  if (import.meta.env.DEV && !userinfo.value.token) {
    try {
      const { data, error } = await useMyFetch('/api/memo/list').post(state.search).json()
      if (error.value) throw new Error('no backend')
      applyList(data.value)
    } catch {
      state.memos = buildMockMemos()
      state.total = state.memos.length
      state.totalPage = 1
    }
    return
  }
  const { data, error } = await useMyFetch('/api/memo/list').post(state.search).json()
  if (!error.value) {
    applyList(data.value)
  }
}

const applyList = (response: ListMemoResponse) => {
  if (state.search.page > 1) {
    state.memos.push(...response.items)
  } else {
    state.memos = response.items
  }
  state.memos.forEach((memo) => {
    memo.resources.forEach((item) => {
      if (item.storageType === 'LOCAL' && item.url.startsWith('/')) {
        item.url = import.meta.env.VITE_BASE_URL + item.url
      }
    })
  })
  state.total = response.total
  state.totalPage = response.totalPage
}

// 开发模式 mock 数据,展示朋友圈主题效果
function buildMockMemos(): Array<MemoDTO> {
  const now = dayjs()
  const img = (n: number, w = 800, h = 800) =>
    `https://picsum.photos/seed/mblog${n}/${w}/${h}`
  return [
    {
      id: 3,
      userId: 1,
      content: '今天去爬山了,山顶的风景真的绝了,随手拍了几张\n\n#生活 #旅行',
      tags: '#生活,#旅行',
      visibility: 'PUBLIC',
      status: 'OK',
      created: now.subtract(2, 'hour').toISOString(),
      updated: now.toISOString(),
      authorName: '阿强',
      authorRole: 'USER',
      email: '',
      bio: '',
      priority: 0,
      commentCount: 3,
      unApprovedCommentCount: 0,
      likeCount: 12,
      enableComment: 1,
      viewCount: 88,
      liked: 1,
      source: 'web',
      resources: [
        { publicId: 'a1', url: img(1), fileType: 'image/jpeg', suffix: '', storageType: 'REMOTE', fileName: '1.jpg' },
        { publicId: 'a2', url: img(2), fileType: 'image/jpeg', suffix: '', storageType: 'REMOTE', fileName: '2.jpg' },
        { publicId: 'a3', url: img(3), fileType: 'image/jpeg', suffix: '', storageType: 'REMOTE', fileName: '3.jpg' },
        { publicId: 'a4', url: img(4), fileType: 'image/jpeg', suffix: '', storageType: 'REMOTE', fileName: '4.jpg' },
        { publicId: 'a5', url: img(5), fileType: 'image/jpeg', suffix: '', storageType: 'REMOTE', fileName: '5.jpg' },
        { publicId: 'a6', url: img(6), fileType: 'image/jpeg', suffix: '', storageType: 'REMOTE', fileName: '6.jpg' },
      ],
    },
    {
      id: 2,
      userId: 1,
      content: '深夜撸代码,记录一下今天的学习成果。\n\n> 保持热爱,奔赴山海\n\n学会了用 Vue3 + Vite 搭建项目,感觉前端也没那么难嘛～',
      tags: '#学习',
      visibility: 'PUBLIC',
      status: 'OK',
      created: now.subtract(1, 'day').subtract(3, 'hour').toISOString(),
      updated: now.toISOString(),
      authorName: '阿强',
      authorRole: 'USER',
      email: '',
      bio: '',
      priority: 1,
      commentCount: 5,
      unApprovedCommentCount: 0,
      likeCount: 23,
      enableComment: 1,
      viewCount: 156,
      liked: 0,
      source: 'TG Bot',
      resources: [],
    },
    {
      id: 1,
      userId: 1,
      content: '分享一首最近单曲循环的歌,太治愈了 🎵\n\n[网易云音乐](https://music.163.com)',
      tags: '#音乐',
      visibility: 'PUBLIC',
      status: 'OK',
      created: now.subtract(3, 'day').toISOString(),
      updated: now.toISOString(),
      authorName: '阿强',
      authorRole: 'USER',
      email: '',
      bio: '',
      priority: 0,
      commentCount: 1,
      unApprovedCommentCount: 0,
      likeCount: 8,
      enableComment: 1,
      viewCount: 66,
      liked: 0,
      source: 'web',
      resources: [{ publicId: 'a7', url: img(7, 800, 500), fileType: 'image/jpeg', suffix: '', storageType: 'REMOTE', fileName: '7.jpg' }],
    },
  ]
}

// 发布/编辑后刷新
changedMemoBus.on(async () => {
  state.search.page = 1
  await reload()
  showInput.value = false
})
</script>

<style scoped lang="scss">
.friends-page {
  min-height: 100vh;
}

.cover {
  .cover-img {
    display: block;
    user-select: none;
  }

  .cover-mask {
    pointer-events: none;
  }
}

/* 时间线日期标签 */
.timeline-date {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 14px 0 8px;

  .dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: #07c160;
    flex-shrink: 0;
    box-shadow: 0 0 0 3px rgba(7, 193, 96, 0.15);
  }

  .label {
    font-size: 13px;
    color: #576b95;
    font-weight: 600;
  }
}

.timeline-items {
  position: relative;
  margin-left: 3px;
  padding-left: 14px;

  /* 时间轴竖线 */
  &::before {
    content: '';
    position: absolute;
    left: 0;
    top: 0;
    bottom: 0;
    width: 2px;
    background: rgba(7, 193, 96, 0.25);
    border-radius: 1px;
  }
}
</style>
