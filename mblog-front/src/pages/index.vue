<route lang="yaml">
  meta:
    layout: friends
</route>
<template>
  <component :is="FriendsIndex"/>
</template>

<script setup lang="ts">
import DefaultIndex from "./defaultIndex.vue"
import FriendsIndex from "./friendsIndex.vue"
</script>