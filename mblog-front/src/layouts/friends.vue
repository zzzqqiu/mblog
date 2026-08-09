<template>
  <div class="friends-layout bg-[#ededed] dark:bg-[#0a0a0a]">
    <div class="friends-container">
      <RouterView />
    </div>
  </div>
</template>

<script setup lang="ts">
// 朋友圈主题布局:沉浸式,无侧边栏,居中容器,微信朋友圈灰底风格
const preferredColor = usePreferredColorScheme()
const themeModelVal = useLocalStorage('themeModel', { theme: 'light' })

themeChangeBus.emit({
  theme: themeModelVal.value.theme || preferredColor.value,
})
</script>

<style scoped lang="scss">
.friends-layout {
  min-height: 100vh;
  transition: background-color 0.3s;
}

.friends-container {
  max-width: 600px;
  margin: 0 auto;
  min-height: 100vh;
}
</style>
