<template>
  <div class="friend-comment">
    <n-mention
      :autosize="{ minRows: 2, maxRows: 5 }"
      :options="usernames"
      :placeholder="placeholder"
      type="textarea"
      v-model:value="content"
      :disabled="!enabelComment"
      size="small"
      class="comment-textarea"
    />
    <div class="fr items-center justify-end mt-1.5 gap-2">
      <template v-if="!userinfo.token">
        <div class="fr items-center gap-1">
          <n-input placeholder="昵称" size="tiny" v-model:value="username" class="!w-20" />
          <n-input placeholder="主页" size="tiny" v-model:value="link" class="!w-24" />
          <n-input placeholder="邮箱" size="tiny" v-model:value="email" class="!w-24" />
        </div>
        <n-button text attr-type="button" type="info" class="text-xs !text-[#576b95]" v-if="!userinfo.token"
          @click="nav2Login">去登录</n-button>
      </template>
      <n-button size="tiny" type="primary" class="!h-7" @click="saveComment" :disabled="!enabelComment">{{ btnName }}
      </n-button>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { MentionOption } from 'naive-ui'

const usernames: Ref<Array<MentionOption>> = ref([])
const content = ref('')
const username = ref('')
const email = ref('')
const link = ref('')
const placeholder = ref('请先登录,再发表评论')
const btnName = ref('发表评论')

const props = defineProps<{ memoId: number, reply?: string }>()
const userinfo = useStorage('userinfo', { token: '' })
const router = useRouter()

const nav2Login = () => {
  router.push('/login?redirect=/')
}

const getUsernames = async () => {
  const { data, error } = await useMyFetch('/api/user/listNames').post().json()
  if (error.value) return
  usernames.value = (data.value as any as Array<string>).map((r) => {
    return {
      label: r,
      value: r,
    }
  })
}

const sessionStorage = useSessionStorage('config', {
  OPEN_COMMENT: false,
  ANONYMOUS_COMMENT: false,
  COMMENT_APPROVED: true,
})

const enabelComment = computed(() => {
  if (sessionStorage.value.OPEN_COMMENT === false) {
    return false
  }
  if (userinfo.value.token) {
    return true
  }
  if (sessionStorage.value.ANONYMOUS_COMMENT === true) {
    return true
  }
  return false
})

const saveComment = async () => {
  const { message } = createDiscreteApi(['message'])

  if (!content.value) {
    message.warning('先填写评论')
    return
  }
  const { error } = await useMyFetch('/api/comment/add')
    .post({
      content: content.value,
      memoId: props.memoId,
      username: username.value || '匿名',
      link: link.value,
      email: email.value,
    })
    .json()
  if (error.value) return
  if (!userinfo.value.token && sessionStorage.value.COMMENT_APPROVED) {
    message.warning('匿名评论成功,等待审核.')
  }
  content.value = ''
  commetSavedBus.emit()
}

onMounted(async () => {
  if (userinfo.value.token) {
    placeholder.value = '评论一下吧~'
    await getUsernames()
  } else {
    placeholder.value = '支持匿名评论,输入您的评论吧,文明发言'
    btnName.value = '回复'
  }

  if (props.reply) {
    placeholder.value = '回复 @' + props.reply
  }
})
</script>

<style scoped lang="scss">
.friend-comment {
  :deep(.n-input) {
    --n-border-radius: 6px;
  }

  :deep(.n-input__textarea-el) {
    font-size: 13px;
  }
}
</style>
