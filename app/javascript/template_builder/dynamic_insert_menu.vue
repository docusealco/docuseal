<template>
  <div class="absolute top-7 left-0 min-w-36 p-1 bg-white border border-neutral-200 rounded-lg shadow-lg">
    <div
      class="relative"
      @pointerenter="$event.pointerType === 'mouse' ? submenu = 'field' : null"
    >
      <button
        class="flex items-center gap-2 w-full px-2 py-1 rounded-md"
        :class="{ 'bg-neutral-100': submenu === 'field' }"
        @click="submenu = submenu === 'field' ? null : 'field'"
      >
        <IconForms
          :width="16"
          :height="16"
          :stroke-width="1.6"
        />
        {{ t('field') }}
        <IconChevronRight
          :width="14"
          :height="14"
          class="ml-auto"
        />
      </button>
      <div
        v-if="submenu === 'field'"
        class="absolute top-0 left-full min-w-40 p-1 bg-white border border-neutral-200 rounded-lg shadow-lg"
      >
        <button
          v-for="(icon, type) in fieldTypesList"
          :key="type"
          class="flex items-center gap-2 w-full px-2 py-1 rounded-md hover:bg-neutral-100"
          @click="[$emit('insert-field', type), $emit('close')]"
        >
          <component
            :is="icon"
            :width="16"
            :height="16"
            :stroke-width="1.6"
          />
          {{ fieldNames[type] }}
        </button>
      </div>
    </div>
    <div
      class="relative"
      @pointerenter="$event.pointerType === 'mouse' ? submenu = 'table' : null"
    >
      <button
        class="flex items-center gap-2 w-full px-2 py-1 rounded-md"
        :class="{ 'bg-neutral-100': submenu === 'table' }"
        @click="submenu = submenu === 'table' ? null : 'table'"
      >
        <IconTable
          :width="16"
          :height="16"
          :stroke-width="1.6"
        />
        {{ t('table') }}
        <IconChevronRight
          :width="14"
          :height="14"
          class="ml-auto"
        />
      </button>
      <div
        v-if="submenu === 'table'"
        class="absolute top-0 left-full w-max p-2 bg-white border border-neutral-200 rounded-lg shadow-lg"
      >
        <div
          v-if="!isMobile"
          class="grid grid-cols-8 gap-0.5 mb-2"
        >
          <template
            v-for="row in 8"
            :key="row"
          >
            <button
              v-for="col in 8"
              :key="col"
              class="w-4 h-4 border rounded-sm"
              :class="row <= tableSize.rows && col <= tableSize.cols ? 'bg-neutral-200 border-neutral-400' : 'bg-white border-neutral-200'"
              :aria-label="`${row} × ${col}`"
              @pointerenter="$event.pointerType === 'mouse' ? tableSize = { rows: row, cols: col } : null"
              @click="[$emit('insert-table', { rows: row, cols: col }), $emit('close')]"
            />
          </template>
        </div>
        <div class="flex items-center justify-center gap-1 text-xs">
          <template
            v-for="key in ['rows', 'cols']"
            :key="key"
          >
            <span v-if="key === 'cols'">×</span>
            <div class="flex items-center border border-neutral-200 rounded-md">
              <button
                class="inline-flex items-center justify-center w-6 h-6 rounded-md hover:bg-neutral-100"
                :aria-label="t(`decrease_${key}`)"
                @click="tableSize[key] = Math.max(tableSize[key] - 1, 1)"
              >
                <IconMinus
                  :width="12"
                  :height="12"
                />
              </button>
              <span class="w-5 text-center">{{ tableSize[key] }}</span>
              <button
                class="inline-flex items-center justify-center w-6 h-6 rounded-md hover:bg-neutral-100"
                :aria-label="t(`increase_${key}`)"
                @click="tableSize[key] = Math.min(tableSize[key] + 1, 20)"
              >
                <IconPlus
                  :width="12"
                  :height="12"
                />
              </button>
            </div>
          </template>
        </div>
        <button
          v-if="isMobile || tableSize.rows > 8 || tableSize.cols > 8"
          class="w-full mt-2 px-2 py-1 rounded-md bg-neutral-100 hover:bg-neutral-200"
          @click="[$emit('insert-table', { ...tableSize }), $emit('close')]"
        >
          {{ t('insert') }}
        </button>
      </div>
    </div>
    <button
      class="flex items-center gap-2 w-full px-2 py-1 rounded-md hover:bg-neutral-100"
      @mouseenter="submenu = null"
      @click="[$emit('insert-variable'), $emit('close')]"
    >
      <IconBracketsContain
        :width="16"
        :height="16"
        :stroke-width="1.6"
      />
      {{ t('variable') }}
    </button>
    <button
      class="flex items-center gap-2 w-full px-2 py-1 rounded-md hover:bg-neutral-100"
      @mouseenter="submenu = null"
      @click="[$emit('insert-image'), $emit('close')]"
    >
      <IconPhoto
        :width="16"
        :height="16"
        :stroke-width="1.6"
      />
      {{ t('image') }}
    </button>
  </div>
</template>

<script>
import { IconPlus, IconMinus, IconForms, IconTable, IconPhoto, IconChevronRight, IconBracketsContain } from '@tabler/icons-vue'
import FieldType from './field_type.vue'

export default {
  name: 'DynamicInsertMenu',
  components: {
    IconPlus,
    IconMinus,
    IconForms,
    IconTable,
    IconPhoto,
    IconChevronRight,
    IconBracketsContain
  },
  inject: ['withPhone', 'withPayment', 'withVerification', 'withKba', 't', 'fieldTypes', 'isMobile'],
  emits: ['insert-field', 'insert-table', 'insert-variable', 'insert-image', 'close'],
  data () {
    return {
      submenu: null,
      tableSize: { rows: 3, cols: 3 }
    }
  },
  computed: {
    fieldNames: FieldType.computed.fieldNames,
    fieldIcons: FieldType.computed.fieldIcons,
    skipTypes: FieldType.computed.skipTypes,
    fieldIconsSorted: FieldType.computed.fieldIconsSorted,
    fieldTypesList () {
      return Object.fromEntries(Object.entries(this.fieldIconsSorted).filter(([type]) => {
        return this.fieldTypes.includes(type) || ((this.withPhone || type !== 'phone') && (this.withPayment || type !== 'payment') && (this.withVerification || type !== 'verification') && (this.withKba || type !== 'kba'))
      }))
    }
  },
  mounted () {
    document.addEventListener('mousedown', this.onDocumentMouseDown)
  },
  beforeUnmount () {
    document.removeEventListener('mousedown', this.onDocumentMouseDown)

    this.$emit('close')
  },
  methods: {
    onDocumentMouseDown (event) {
      if (!event.composedPath().includes(this.$el.parentElement)) {
        this.$emit('close')
      }
    }
  }
}
</script>
