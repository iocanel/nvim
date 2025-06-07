<template>
  <div class='{{_lua:(vim.fn.expand("%:t:r")):gsub("(%l)(%u)", "%1-%2"):gsub("[%s_]", "-"):lower()_}}'></div>
</template>

<script setup lang="ts">
</script>

<style scoped>
.{{_lua:(vim.fn.expand("%:t:r")):gsub("(%l)(%u)", "%1-%2"):gsub("[%s_]", "-"):lower()_}} {
}
</style>
