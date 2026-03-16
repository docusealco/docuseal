<template>
  <div>
    <div
      v-if="!schemaEntries.length"
      class="text-center py-4 px-2"
    >
      <p class="font-medium">
        {{ t('no_variables') }}
      </p>
      <p class="text-sm mt-1">
        {{ t('no_variables_description') }}
      </p>
    </div>
    <template v-else>
      <template
        v-for="([key, node], index) in schemaEntries"
        :key="key"
      >
        <div v-if="isGroup(node)">
          <hr
            v-if="index > 0"
            class="border-base-300"
          >
          <label class="peer flex items-center py-1.5 cursor-pointer select-none">
            <span class="w-5 flex justify-center items-center">
              <input
                type="checkbox"
                class="hidden peer"
                checked
              >
              <IconChevronDown
                class="hidden peer-checked:block ml-0.5"
                :width="14"
                :stroke-width="1.6"
              />
              <IconChevronRight
                class="block peer-checked:hidden ml-0.5"
                :width="14"
                :stroke-width="1.6"
              />
            </span>
            <span class="ml-1">{{ key }}</span>
            <span
              v-if="node.type === 'array'"
              class="text-xs bg-base-200 rounded px-1 ml-1"
            >{{ t('list') }}</span>
          </label>
          <div class="hidden peer-has-[:checked]:block pl-5">
            <template
              v-for="[varNode, varPath] in nestedVariables(node, key)"
              :key="varPath"
            >
              <hr class="border-base-300">
              <DynamicVariable
                :path="varPath"
                :group-key="key"
                :editable="editable"
                :schema="varNode"
              />
            </template>
          </div>
        </div>
        <template v-else>
          <hr
            v-if="index > 0"
            class="border-base-300"
          >
          <DynamicVariable
            :path="key"
            :editable="editable"
            :schema="node.type === 'array' && node.items ? node.items : node"
            :is-array="node.type === 'array'"
          />
        </template>
      </template>
    </template>
  </div>
</template>

<script>
import DynamicVariable from './dynamic_variable'
import { IconChevronDown, IconChevronRight } from '@tabler/icons-vue'

export default {
  name: 'DynamicVariables',
  components: {
    DynamicVariable,
    IconChevronDown,
    IconChevronRight
  },
  inject: ['t', 'template', 'save', 'backgroundColor'],
  props: {
    editable: {
      type: Boolean,
      required: false,
      default: true
    }
  },
  computed: {
    schemaEntries () {
      return Object.entries(this.template.variables_schema || {}).filter(([, node]) => !node.disabled)
    }
  },
  methods: {
    isGroup (node) {
      return (node.type === 'object' && node.properties) || (node.type === 'array' && node.items?.type === 'object' && node.items?.properties)
    },
    nestedVariables (node, groupKey) {
      const properties = node.type === 'array' ? node.items?.properties : node.properties

      if (!properties) return []

      const prefix = node.type === 'array' ? `${groupKey}[]` : groupKey

      return this.collectLeafVariables(properties, prefix)
    },
    collectLeafVariables (properties, prefix) {
      return Object.entries(properties).reduce((result, [key, node]) => {
        if (node.disabled) return result

        const path = `${prefix}.${key}`

        if (node.type === 'object' && node.properties) {
          result.push(...this.collectLeafVariables(node.properties, path))
        } else if (node.type === 'array' && node.items?.properties) {
          result.push(...this.collectLeafVariables(node.items.properties, `${path}[]`))
        } else {
          result.push([node, path])
        }

        return result
      }, [])
    }
  }
}
</script>
