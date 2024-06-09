<template>
  <div
    class="modal modal-open items-start !animate-none overflow-y-auto"
  >
    <div
      class="absolute top-0 bottom-0 right-0 left-0"
      @click.prevent="$emit('close')"
    />
    <div class="modal-box pt-4 pb-6 px-6 mt-20 max-h-none w-full max-w-xl">
      <div class="flex justify-between items-center border-b pb-2 mb-2 font-medium">
        <span>
          {{ t('condition') }} - {{ field.name || buildDefaultName(field, template.fields) }}
        </span>
        <a
          href="#"
          class="text-xl"
          @click.prevent="$emit('close')"
        >&times;</a>
      </div>
      <div>
        <div
          v-if="!withConditions"
          class="bg-base-300 rounded-xl py-2 px-3 text-center"
        >
          <a
            href="https://www.docuseal.co/pricing"
            target="_blank"
            class="link"
          >Available in Pro</a>
        </div>
        <form @submit.prevent="validateSaveAndClose">
          <div class="my-4 space-y-5">
            <div
              v-for="(condition, cindex) in conditions"
              :key="cindex"
              class="space-y-4 relative"
            >
              <div
                v-if="conditions.length > 1"
                class="flex justify-between border-b mx-1 -mb-1 pb-1"
              >
                <span class="text-sm">
                  {{ t('condition') }} {{ cindex + 1 }}
                </span>
                <a
                  href="#"
                  class="link text-sm"
                  @click.prevent="conditions.splice(cindex, 1)"
                > {{ t('remove') }}</a>
              </div>
              <select
                class="select select-bordered select-sm w-full bg-white h-11 pl-4 text-base font-normal"
                required
                @change="[
                  condition.field_uuid = $event.target.value,
                  delete condition.value,
                  (conditionActions(condition).includes(condition.action) ? '' : condition.action = conditionActions(condition)[0])
                ]"
              >
                <option
                  value=""
                  disabled
                  :selected="!condition.field_uuid"
                >
                  {{ t('select_field_') }}
                </option>
                <option
                  v-for="f in fields"
                  :key="f.uuid"
                  :value="f.uuid"
                  :selected="condition.field_uuid === f.uuid"
                >
                  {{ f.name || buildDefaultName(f, template.fields) }}
                </option>
              </select>
              <select
                v-model="condition.action"
                class="select select-bordered select-sm w-full h-11 pl-4 text-base font-normal"
                :class="{ 'bg-white': condition.field_uuid, 'bg-base-300': !condition.field_uuid }"
                :required="condition.field_uuid"
              >
                <option
                  v-for="action in conditionActions(condition)"
                  :key="action"
                  :value="action"
                >
                  {{ t(action) }}
                </option>
              </select>
              <select
                v-if="conditionField(condition)?.options?.length"
                class="select select-bordered select-sm w-full bg-white h-11 pl-4 text-base font-normal"
                required
                @change="condition.value = $event.target.value"
              >
                <option
                  value=""
                  disabled
                  selected
                >
                  {{ t('select_value_') }}
                </option>
                <option
                  v-for="(option, index) in conditionField(condition).options"
                  :key="option.uuid"
                  :value="option.uuid"
                  :selected="condition.value === option.uuid"
                >
                  {{ option.value || `${t('option')} ${index + 1}` }}
                </option>
              </select>
            </div>
          </div>
          <a
            href="#"
            class="inline float-right link text-right mb-3 px-2"
            @click.prevent="conditions.push({})"
          > + {{ t('add_condition') }}</a>
          <button
            class="base-button w-full mt-2"
          >
            {{ t('save') }}
          </button>
        </form>
        <div
          v-if="field.conditions?.[0]?.field_uuid"
          class="text-center w-full mt-4"
        >
          <button
            class="link"
            @click="[conditions = [], delete field.conditions, validateSaveAndClose()]"
          >
            {{ t('remove_condition') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ConditionModal',
  inject: ['t', 'save', 'template', 'withConditions'],
  props: {
    field: {
      type: Object,
      required: true
    },
    buildDefaultName: {
      type: Function,
      required: true
    }
  },
  emits: ['close'],
  data () {
    return {
      conditions: this.field.conditions?.[0] ? JSON.parse(JSON.stringify(this.field.conditions)) : [{}]
    }
  },
  computed: {
    fields () {
      return this.template.fields.reduce((acc, f) => {
        if (f !== this.field && f.submitter_uuid === this.field.submitter_uuid) {
          acc.push(f)
        }

        return acc
      }, [])
    }
  },
  created () {
    this.field.conditions ||= []
  },
  methods: {
    conditionField (condition) {
      return this.fields.find((f) => f.uuid === condition.field_uuid)
    },
    conditionActions (condition) {
      return this.fieldActions(this.conditionField(condition))
    },
    fieldActions (field) {
      const actions = []

      if (!field) {
        return actions
      }

      if (field.type === 'checkbox') {
        actions.push('checked', 'unchecked')
      } else if (['radio', 'select'].includes(field.type)) {
        actions.push('equal', 'not_equal')
      } else if (['multiple'].includes(field.type)) {
        actions.push('contains', 'does_not_contain')
      } else {
        actions.push('not_empty', 'empty')
      }

      return actions
    },
    validateSaveAndClose () {
      if (!this.withConditions) {
        return alert('Available only in Pro')
      }

      if (this.conditions.find((f) => f.field_uuid)) {
        this.field.conditions = this.conditions
      } else {
        delete this.field.conditions
      }

      this.save()
      this.$emit('close')
    }
  }
}
</script>
