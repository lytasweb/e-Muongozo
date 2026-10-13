cat > frontend/src/App.vue << 'EOF'
<template>
  <router-view />
</template>

<script setup>
// App is a pure router outlet.
// Each view brings its own layout (AppShell for logged-in pages,
// auth-root for login/register/entity pages).
</script>
EOF