<template>
  <div class="container">
    <div class="header">
      <h1>blackSwan API 测试页面</h1>
      <p>快速验证后端接口连通性</p>
    </div>

    <div class="content">
      <div class="config-section">
        <h2>服务器状态</h2>
        <div class="status-badge" :class="serverStatus ? 'connected' : 'disconnected'">
          <span class="status-dot" :class="serverStatus ? 'connected' : 'disconnected'"></span>
          <span>{{ serverStatus ? '后端已连接 (http://localhost:8080)' : '后端未连接' }}</span>
        </div>
      </div>

      <div class="test-section">
        <div class="test-card">
          <h3>
            <span class="method-badge">GET</span>
            健康检查
          </h3>
          <p class="description">检查服务是否正常运行</p>
          <div class="endpoint">GET /health</div>
          <button @click="testHealth" :disabled="loading.health">
            {{ loading.health ? '请求中...' : '测试接口' }}
          </button>
          <div v-if="results.health" class="result" :class="results.health.success ? 'success' : 'error'">
            <div class="result-header">
              <span class="status-indicator" :class="results.health.success ? 'success' : 'error'"></span>
              {{ results.health.success ? '成功' : '失败' }}: {{ results.health.message }}
            </div>
            <div v-if="results.health.data" class="result-body">{{ formatJson(results.health.data) }}</div>
          </div>
        </div>

        <div class="test-card">
          <h3>
            <span class="method-badge">GET</span>
            Ping 测试
          </h3>
          <p class="description">测试 API v1 路由是否正常</p>
          <div class="endpoint">GET /v1/ping</div>
          <button @click="testPing" :disabled="loading.ping">
            {{ loading.ping ? '请求中...' : '测试接口' }}
          </button>
          <div v-if="results.ping" class="result" :class="results.ping.success ? 'success' : 'error'">
            <div class="result-header">
              <span class="status-indicator" :class="results.ping.success ? 'success' : 'error'"></span>
              {{ results.ping.success ? '成功' : '失败' }}: {{ results.ping.message }}
            </div>
            <div v-if="results.ping.data" class="result-body">{{ formatJson(results.ping.data) }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const serverStatus = ref(false)
const loading = ref({
  health: false,
  ping: false
})
const results = ref({
  health: null,
  ping: null
})

const formatJson = (data) => {
  return JSON.stringify(data, null, 2)
}

const checkServerStatus = async () => {
  try {
    const response = await fetch('/health')
    serverStatus.value = response.ok
  } catch (error) {
    serverStatus.value = false
  }
}

const testHealth = async () => {
  loading.value.health = true
  results.value.health = null

  try {
    const response = await fetch('/health')
    const data = await response.json()

    results.value.health = {
      success: response.ok,
      message: `HTTP ${response.status}`,
      data: data
    }
  } catch (error) {
    results.value.health = {
      success: false,
      message: error.message,
      data: null
    }
  } finally {
    loading.value.health = false
  }
}

const testPing = async () => {
  loading.value.ping = true
  results.value.ping = null

  try {
    const response = await fetch('/v1/ping')
    const data = await response.json()

    results.value.ping = {
      success: response.ok,
      message: `HTTP ${response.status}`,
      data: data
    }
  } catch (error) {
    results.value.ping = {
      success: false,
      message: error.message,
      data: null
    }
  } finally {
    loading.value.ping = false
  }
}

onMounted(() => {
  checkServerStatus()
})
</script>
