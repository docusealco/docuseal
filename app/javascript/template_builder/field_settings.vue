<template>
  <div
    v-if="field.type === 'number'"
    class="py-1.5 px-1 relative"
    @click.stop
  >
    <select
      :placeholder="t('format')"
      class="select select-bordered select-xs font-normal w-full max-w-xs !h-7 !outline-0 bg-transparent"
      @change="[field.preferences ||= {}, field.preferences.format = $event.target.value, save()]"
    >
      <option
        v-for="format in numberFormats"
        :key="format"
        :value="format"
        :selected="format === field.preferences?.format || (format === 'none' && !field.preferences?.format)"
      >
        {{ formatNumber(123456789.567, format) }}
      </option>
    </select>
    <label
      :style="{ backgroundColor }"
      class="absolute -top-1 left-2.5 px-1 h-4"
      style="font-size: 8px"
    >
      {{ t('format') }}
    </label>
  </div>
  <div
    v-if="['number'].includes(field.type)"
    class="py-1.5 px-1 relative"
    @click.stop
  >
    <select
      class="select select-bordered select-xs w-full max-w-xs h-7 !outline-0 font-normal bg-transparent"
      @change="[field.preferences ||= {}, field.preferences.align = $event.target.value, save()]"
    >
      <option
        v-for="value in ['left', 'right', 'center']"
        :key="value"
        :selected="field.preferences?.align ? value === field.preferences.align : value === 'left'"
        :value="value"
      >
        {{ t(value) }}
      </option>
    </select>
    <label
      :style="{ backgroundColor }"
      class="absolute -top-1 left-2.5 px-1 h-4"
      style="font-size: 8px"
    >
      {{ t('align') }}
    </label>
  </div>
  <div
    v-if="['select', 'radio'].includes(field.type) && !defaultField"
    class="py-1.5 px-1 relative"
    @click.stop
  >
    <select
      :placeholder="t('default_value')"
      dir="auto"
      class="select select-bordered select-xs w-full max-w-xs h-7 !outline-0 font-normal bg-transparent"
      @change="[field.default_value = $event.target.value, !field.default_value && delete field.default_value, save()]"
    >
      <option
        value=""
        :selected="!field.default_value"
      >
        {{ t('none') }}
      </option>
      <option
        v-for="(option, index) in field.options || []"
        :key="option.uuid"
        :value="option.value || `${t('option')} ${index + 1}`"
        :selected="field.default_value === (option.value || `${t('option')} ${index + 1}`)"
      >
        {{ option.value || `${t('option')} ${index + 1}` }}
      </option>
    </select>
    <label
      :style="{ backgroundColor }"
      class="absolute -top-1 left-2.5 px-1 h-4"
      style="font-size: 8px"
    >
      {{ t('default_value') }}
    </label>
  </div>
  <div
    v-if="['text', 'number'].includes(field.type) && !defaultField"
    class="py-1.5 px-1 relative"
    @click.stop
  >
    <input
      v-model="field.default_value"
      :placeholder="t('default_value')"
      dir="auto"
      :type="field.type"
      class="input input-bordered input-xs w-full max-w-xs h-7 !outline-0 bg-transparent"
      @blur="save"
    >
    <label
      v-if="field.default_value"
      :style="{ backgroundColor }"
      class="absolute -top-1 left-2.5 px-1 h-4"
      style="font-size: 8px"
    >
      {{ t('default_value') }}
    </label>
  </div>
  <div
    v-if="['text', 'cells'].includes(field.type)"
    class="py-1.5 px-1 relative"
    @click.stop
  >
    <select
      class="select select-bordered select-xs w-full max-w-xs h-7 !outline-0 font-normal bg-transparent"
      @change="onChangeValidation"
    >
      <option
        :selected="!field.validation"
        value=""
      >
        {{ t('none') }}
      </option>
      <option
        v-for="(key, value) in validations"
        :key="key"
        :selected="field.validation?.pattern ? value === field.validation.pattern : value === 'none'"
        :value="value"
      >
        {{ t(key) }}
      </option>
      <option
        :selected="field.validation && !validations[field.validation.pattern]"
        :value="validations[field.validation?.pattern] || !field.validation?.pattern ? 'custom' : field.validation?.pattern"
      >
        {{ t('custom') }}
      </option>
    </select>
    <label
      :style="{ backgroundColor }"
      class="absolute -top-1 left-2.5 px-1 h-4"
      style="font-size: 8px"
    >
      {{ t('validation') }}
    </label>
  </div>
  <div
    v-if="['text', 'cells'].includes(field.type) && field.validation && !validations[field.validation.pattern]"
    class="py-1.5 px-1 relative"
    @click.stop
  >
    <input
      ref="validationCustom"
      v-model="field.validation.pattern"
      :placeholder="t('regexp_validation')"
      dir="auto"
      class="input input-bordered input-xs w-full max-w-xs h-7 !outline-0 bg-transparent"
      @blur="save"
    >
    <label
      v-if="field.validation.pattern"
      :style="{ backgroundColor }"
      class="absolute -top-1 left-2.5 px-1 h-4"
      style="font-size: 8px"
    >
      {{ t('regexp_validation') }}
    </label>
  </div>
  <div
    v-if="field.type === 'date'"
    class="py-1.5 px-1 relative"
    @click.stop
  >
    <select
      v-model="field.preferences.format"
      :placeholder="t('format')"
      class="select select-bordered select-xs font-normal w-full max-w-xs !h-7 !outline-0 bg-transparent"
      @change="save"
    >
      <option
        v-for="format in dateFormats"
        :key="format"
        :value="format"
      >
        {{ formatDate(new Date(), format) }}
      </option>
    </select>
    <label
      :style="{ backgroundColor }"
      class="absolute -top-1 left-2.5 px-1 h-4"
      style="font-size: 8px"
    >
      {{ t('format') }}
    </label>
  </div>
  <div
    v-if="field.type === 'signature'"
    class="py-1.5 px-1 relative"
    @click.stop
  >
    <select
      :placeholder="t('format')"
      class="select select-bordered select-xs font-normal w-full max-w-xs !h-7 !outline-0 bg-transparent"
      @change="[field.preferences.format = $event.target.value, save()]"
    >
      <option
        value="any"
        :selected="!field.preferences?.format || field.preferences.format === 'any'"
      >
        {{ t('any') }}
      </option>
      <option
        value="drawn"
        :selected="field.preferences?.format === 'drawn'"
      >
        {{ t('drawn') }}
      </option>
      <option
        value="typed"
        :selected="field.preferences?.format === 'typed'"
      >
        {{ t('typed') }}
      </option>
    </select>
    <label
      :style="{ backgroundColor }"
      class="absolute -top-1 left-2.5 px-1 h-4"
      style="font-size: 8px"
    >
      {{ t('format') }}
    </label>
  </div>
  <li
    v-if="withRequired && field.type != 'phone' && field.type != 'stamp'"
    @click.stop
  >
    <label class="cursor-pointer py-1.5">
      <input
        v-model="field.required"
        type="checkbox"
        :disabled="!editable || defaultField"
        class="toggle toggle-xs"
        @update:model-value="save"
      >
      <span class="label-text">{{ t('required') }}</span>
    </label>
  </li>
  <li
    v-if="field.type == 'stamp'"
    @click.stop
  >
    <label class="cursor-pointer py-1.5">
      <input
        :checked="field.preferences?.with_logo != false"
        type="checkbox"
        class="toggle toggle-xs"
        @change="[field.preferences ||= {}, field.preferences.with_logo = field.preferences.with_logo == false, save()]"
      >
      <span class="label-text">{{ t('with_logo') }}</span>
    </label>
  </li>
  <li
    v-if="field.type == 'checkbox'"
    @click.stop
  >
    <label class="cursor-pointer py-1.5">
      <input
        v-model="field.default_value"
        type="checkbox"
        class="toggle toggle-xs"
        @update:model-value="[field.default_value = $event, field.readonly = $event, save()]"
      >
      <span class="label-text">{{ t('checked') }}</span>
    </label>
  </li>
  <li
    v-if="field.type == 'date'"
    @click.stop
  >
    <label class="cursor-pointer py-1.5">
      <input
        v-model="field.readonly"
        type="checkbox"
        class="toggle toggle-xs"
        @update:model-value="[field.default_value = $event ? '{{date}}' : null, field.readonly = $event, save()]"
      >
      <span class="label-text">{{ t('set_signing_date') }}</span>
    </label>
  </li>
  <li
    v-if="['text', 'number'].includes(field.type) && !defaultField"
    @click.stop
  >
    <label class="cursor-pointer py-1.5">
      <input
        v-model="field.readonly"
        type="checkbox"
        class="toggle toggle-xs"
        @update:model-value="save"
      >
      <span class="label-text">{{ t('read_only') }}</span>
    </label>
  </li>
  <hr
    v-if="field.type != 'stamp'"
    class="pb-0.5 mt-0.5"
  >
  <li
    v-if="field.type != 'stamp'"
  >
    <label
      class="label-text cursor-pointer text-center w-full flex items-center"
      @click="$emit('click-description')"
    >
      <IconInfoCircle
        width="18"
      />
      <span class="text-sm">
        {{ t('description') }}
      </span>
    </label>
  </li>
  <li
    v-if="field.type != 'stamp'"
  >
    <label
      class="label-text cursor-pointer text-center w-full flex items-center"
      @click="$emit('click-condition')"
    >
      <IconRouteAltLeft
        width="18"
      />
      <span class="text-sm">
        {{ t('condition') }}
      </span>
    </label>
  </li>
  <li v-if="field.type == 'number'">
    <label
      class="label-text cursor-pointer text-center w-full flex items-center"
      @click="$emit('click-formula')"
    >
      <IconMathFunction
        width="18"
      />
      <span class="text-sm">
        {{ t('formula') }}
      </span>
    </label>
  </li>
  <hr class="pb-0.5 mt-0.5">
  <template v-if="withAreas">
    <li
      v-for="(area, index) in sortedAreas"
      :key="index"
    >
      <a
        href="#"
        class="text-sm py-1 px-2"
        @click.prevent="$emit('scroll-to', area)"
      >
        <IconShape
          :width="20"
          :stroke-width="1.6"
        />
        {{ t('page') }}
        <template v-if="template.schema.length > 1">{{ template.schema.findIndex((item) => item.attachment_uuid === area.attachment_uuid) + 1 }}-</template>{{ area.page + 1 }}
      </a>
    </li>
    <li v-if="!field.areas?.length || !['radio', 'multiple'].includes(field.type)">
      <a
        href="#"
        class="text-sm py-1 px-2"
        @click.prevent="$emit('set-draw', { field })"
      >
        <IconNewSection
          :width="20"
          :stroke-width="1.6"
        />
        {{ t('draw_new_area') }}
      </a>
    </li>
  </template>
  <li v-if="field.areas?.length === 1 && ['date', 'signature', 'initials', 'text', 'cells'].includes(field.type)">
    <a
      href="#"
      class="text-sm py-1 px-2"
      @click.prevent="copyToAllPages(field)"
    >
      <IconCopy
        :width="20"
        :stroke-width="1.6"
      />
      {{ t('copy_to_all_pages') }}
    </a>
  </li>
</template>

<script>
import { IconRouteAltLeft, IconShape, IconMathFunction, IconNewSection, IconInfoCircle, IconCopy } from '@tabler/icons-vue'

export default {
  name: 'FieldSettings',
  components: {
    IconShape,
    IconInfoCircle,
    IconMathFunction,
    IconRouteAltLeft,
    IconCopy,
    IconNewSection
  },
  inject: ['template', 'save', 't'],
  props: {
    field: {
      type: Object,
      required: true
    },
    backgroundColor: {
      type: String,
      required: false,
      default: null
    },
    defaultField: {
      type: Object,
      required: false,
      default: null
    },
    withRequired: {
      type: Boolean,
      required: false,
      default: true
    },
    withAreas: {
      type: Boolean,
      required: false,
      default: true
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    }
  },
  emits: ['set-draw', 'scroll-to', 'click-formula', 'click-description', 'click-condition'],
  data () {
    return {
    }
  },
  computed: {
    schemaAttachmentsIndexes () {
      return (this.template.schema || []).reduce((acc, item, index) => {
        acc[item.attachment_uuid] = index

        return acc
      }, {})
    },
    numberFormats () {
      return [
        'none',
        'comma',
        'dot',
        'space'
      ]
    },
    dateFormats () {
      const formats = [
        'MM/DD/YYYY',
        'DD/MM/YYYY',
        'YYYY-MM-DD',
        'DD-MM-YYYY',
        'DD.MM.YYYY',
        'MMM D, YYYY',
        'MMMM D, YYYY',
        'D MMM YYYY',
        'D MMMM YYYY'
      ]

      if (Intl.DateTimeFormat().resolvedOptions().timeZone?.includes('Seoul') || navigator.language?.startsWith('ko')) {
        formats.push('YYYY년 MM월 DD일')
      }

      if (this.field.preferences?.format && !formats.includes(this.field.preferences.format)) {
        formats.unshift(this.field.preferences.format)
      }

      return formats
    },
    validations () {
      return {
        '^[0-9]{3}-[0-9]{2}-[0-9]{4}$': 'ssn',
        '^[0-9]{2}-[0-9]{7}$': 'ein',
        '^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$': 'email',
        '^https?://.*': 'url',
        '^[0-9]{5}(?:-[0-9]{4})?$': 'zip',
        '^[0-9]+$': 'numbers_only',
        '^[a-zA-Z]+$': 'letters_only'
      }
    },
    sortedAreas () {
      return (this.field.areas || []).sort((a, b) => {
        return this.schemaAttachmentsIndexes[a.attachment_uuid] - this.schemaAttachmentsIndexes[b.attachment_uuid]
      })
    }
  },
  methods: {
    onChangeValidation (event) {
      if (event.target.value === 'custom') {
        this.field.validation = { pattern: '' }

        this.$nextTick(() => this.$refs.validationCustom.focus())
      } else if (event.target.value) {
        this.field.validation ||= {}
        this.field.validation.pattern = event.target.value
      } else {
        delete this.field.validation
      }

      this.save()
    },
    copyToAllPages (field) {
      const areaString = JSON.stringify(field.areas[0])

      this.template.documents.forEach((attachment) => {
        const numberOfPages = attachment.metadata?.pdf?.number_of_pages || attachment.preview_images.length

        for (let page = 0; page <= numberOfPages - 1; page++) {
          if (!field.areas.find((area) => area.attachment_uuid === attachment.uuid && area.page === page)) {
            field.areas.push({ ...JSON.parse(areaString), attachment_uuid: attachment.uuid, page })
          }
        }
      })

      this.$emit('scroll-to', this.field.areas[this.field.areas.length - 1])

      this.save()
    },
    formatNumber (number, format) {
      if (format === 'comma') {
        return new Intl.NumberFormat('en-US').format(number)
      } else if (format === 'dot') {
        return new Intl.NumberFormat('de-DE').format(number)
      } else if (format === 'space') {
        return new Intl.NumberFormat('fr-FR').format(number)
      } else {
        return number
      }
    },
    formatDate (date, format) {
      const monthFormats = {
        M: 'numeric',
        MM: '2-digit',
        MMM: 'short',
        MMMM: 'long'
      }

      const dayFormats = {
        D: 'numeric',
        DD: '2-digit'
      }

      const yearFormats = {
        YYYY: 'numeric',
        YY: '2-digit'
      }

      const parts = new Intl.DateTimeFormat([], {
        day: dayFormats[format.match(/D+/)],
        month: monthFormats[format.match(/M+/)],
        year: yearFormats[format.match(/Y+/)]
      }).formatToParts(date)

      return format
        .replace(/D+/, parts.find((p) => p.type === 'day').value)
        .replace(/M+/, parts.find((p) => p.type === 'month').value)
        .replace(/Y+/, parts.find((p) => p.type === 'year').value)
    }
  }
}
</script>
