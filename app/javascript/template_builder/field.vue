<template>
  <div
    class="list-field group mb-2"
  >
    <div
      class="border border-base-300 rounded rounded-tr-none relative group"
      :style="{ backgroundColor: backgroundColor }"
    >
      <div class="flex items-center justify-between relative group/contenteditable-container">
        <div
          class="absolute top-0 bottom-0 right-0 left-0 cursor-pointer"
          @click="scrollToFirstArea"
        />
        <div class="flex items-center p-1 space-x-1">
          <FieldType
            v-model="field.type"
            :editable="editable && !defaultField"
            :button-width="20"
            :menu-classes="'mt-1.5'"
            :menu-style="{ backgroundColor: dropdownBgColor }"
            @update:model-value="[maybeUpdateOptions(), save()]"
            @click="scrollToFirstArea"
          />
          <Contenteditable
            ref="name"
            :model-value="(defaultField ? (field.title || field.name) : field.name) || defaultName"
            :editable="editable && !defaultField"
            :icon-inline="true"
            :icon-width="18"
            :icon-stroke-width="1.6"
            @focus="[onNameFocus(), scrollToFirstArea()]"
            @blur="onNameBlur"
          />
        </div>
        <div
          v-if="isNameFocus"
          class="flex items-center relative"
        >
          <template v-if="field.type != 'phone'">
            <input
              :id="`required-checkbox-${field.uuid}`"
              v-model="field.required"
              type="checkbox"
              class="checkbox checkbox-xs no-animation rounded"
              @mousedown.prevent
            >
            <label
              :for="`required-checkbox-${field.uuid}`"
              class="label text-xs"
              @click.prevent="field.required = !field.required"
              @mousedown.prevent
            >{{ t('required') }}</label>
          </template>
        </div>
        <div
          v-else-if="editable"
          class="flex items-center space-x-1"
        >
          <button
            v-if="field && !field.areas.length"
            :title="t('draw')"
            class="relative cursor-pointer text-transparent group-hover:text-base-content"
            @click="$emit('set-draw', { field })"
          >
            <IconNewSection
              :width="18"
              :stroke-width="1.6"
            />
          </button>
          <button
            v-if="field.preferences?.formula"
            class="relative cursor-pointer text-transparent group-hover:text-base-content"
            :title="t('formula')"
            @click="isShowFormulaModal = true"
          >
            <IconMathFunction
              :width="18"
              :stroke-width="1.6"
            />
          </button>
          <button
            v-if="field.conditions?.length"
            class="relative cursor-pointer text-transparent group-hover:text-base-content"
            :title="t('condition')"
            @click="isShowConditionsModal = true"
          >
            <IconRouteAltLeft
              :width="18"
              :stroke-width="1.6"
            />
          </button>
          <PaymentSettings
            v-if="field.type === 'payment'"
            :field="field"
          />
          <span
            v-else
            class="dropdown dropdown-end"
            @mouseenter="renderDropdown = true"
            @touchstart="renderDropdown = true"
          >
            <label
              tabindex="0"
              :title="t('settings')"
              class="cursor-pointer text-transparent group-hover:text-base-content"
            >
              <IconSettings
                :width="18"
                :stroke-width="1.6"
              />
            </label>
            <ul
              v-if="renderDropdown"
              tabindex="0"
              class="mt-1.5 dropdown-content menu menu-xs p-2 shadow rounded-box w-52 z-10"
              :style="{ backgroundColor: dropdownBgColor }"
              draggable="true"
              @dragstart.prevent.stop
              @click="closeDropdown"
            >
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
                  :style="{ backgroundColor: dropdownBgColor }"
                  class="absolute -top-1 left-2.5 px-1 h-4"
                  style="font-size: 8px"
                >
                  {{ t('align') }}
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
                  :style="{ backgroundColor: dropdownBgColor }"
                  class="absolute -top-1 left-2.5 px-1 h-4"
                  style="font-size: 8px"
                >
                  {{ t('default_value') }}
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
                  :style="{ backgroundColor: dropdownBgColor }"
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
                  :style="{ backgroundColor: dropdownBgColor }"
                  class="absolute -top-1 left-2.5 px-1 h-4"
                  style="font-size: 8px"
                >
                  {{ t('format') }}
                </label>
              </div>
              <li
                v-if="field.type != 'phone' && field.type != 'stamp'"
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
                  @click="isShowDescriptionModal = !isShowDescriptionModal"
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
                  @click="isShowConditionsModal = !isShowConditionsModal"
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
                  @click="isShowFormulaModal = true"
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
            </ul>
          </span>
          <button
            class="relative text-transparent group-hover:text-base-content pr-1"
            :title="t('remove')"
            @click="$emit('remove', field)"
          >
            <IconTrashX
              :width="18"
              :stroke-width="1.6"
            />
          </button>
        </div>
      </div>
      <div
        v-if="field.options"
        ref="options"
        class="border-t border-base-300 mx-2 pt-2 space-y-1.5"
        draggable="true"
        @dragstart.prevent.stop
      >
        <div
          v-for="(option, index) in field.options"
          :key="option.uuid"
          class="flex space-x-1.5 items-center"
        >
          <span class="text-sm w-3.5">
            {{ index + 1 }}.
          </span>
          <div
            v-if="editable && ['radio', 'multiple'].includes(field.type) && (index > 0 || field.areas.find((a) => a.option_uuid) || !field.areas.length) && !field.areas.find((a) => a.option_uuid === option.uuid)"
            class="items-center flex w-full"
          >
            <input
              v-model="option.value"
              class="w-full input input-primary input-xs text-sm bg-transparent !pr-7 -mr-6"
              type="text"
              dir="auto"
              required
              :placeholder="`${t('option')} ${index + 1}`"
              @blur="save"
            >
            <button
              :title="t('draw')"
              tabindex="-1"
              @click.prevent="$emit('set-draw', { field, option })"
            >
              <IconNewSection
                :width="18"
                :stroke-width="1.6"
              />
            </button>
          </div>
          <input
            v-else
            v-model="option.value"
            class="w-full input input-primary input-xs text-sm bg-transparent"
            :placeholder="`${t('option')} ${index + 1}`"
            type="text"
            :readonly="!editable"
            required
            dir="auto"
            @focus="maybeFocusOnOptionArea(option)"
            @blur="save"
          >
          <button
            v-if="editable"
            class="text-sm w-3.5"
            tabindex="-1"
            @click="removeOption(option)"
          >
            &times;
          </button>
        </div>
        <div
          v-if="field.options && !editable"
          class="pb-1"
        />
        <button
          v-else-if="field.options && editable"
          class="text-center text-sm w-full pb-1"
          @click="addOption"
        >
          + {{ t('add_option') }}
        </button>
      </div>
    </div>
    <Teleport
      v-if="isShowFormulaModal"
      :to="modalContainerEl"
    >
      <FormulaModal
        :field="field"
        :editable="editable && !defaultField"
        :build-default-name="buildDefaultName"
        @close="isShowFormulaModal = false"
      />
    </Teleport>
    <Teleport
      v-if="isShowConditionsModal"
      :to="modalContainerEl"
    >
      <ConditionsModal
        :field="field"
        :build-default-name="buildDefaultName"
        @close="isShowConditionsModal = false"
      />
    </Teleport>
    <Teleport
      v-if="isShowDescriptionModal"
      :to="modalContainerEl"
    >
      <DescriptionModal
        :field="field"
        :editable="editable && !defaultField"
        :build-default-name="buildDefaultName"
        @close="isShowDescriptionModal = false"
      />
    </Teleport>
  </div>
</template>

<script>
import Contenteditable from './contenteditable'
import FieldType from './field_type'
import PaymentSettings from './payment_settings'
import FormulaModal from './formula_modal'
import ConditionsModal from './conditions_modal'
import DescriptionModal from './description_modal'
import { IconInfoCircle, IconRouteAltLeft, IconMathFunction, IconShape, IconNewSection, IconTrashX, IconCopy, IconSettings } from '@tabler/icons-vue'
import { v4 } from 'uuid'

export default {
  name: 'TemplateField',
  components: {
    Contenteditable,
    IconSettings,
    IconShape,
    PaymentSettings,
    IconNewSection,
    IconInfoCircle,
    FormulaModal,
    DescriptionModal,
    ConditionsModal,
    IconRouteAltLeft,
    IconTrashX,
    IconMathFunction,
    IconCopy,
    FieldType
  },
  inject: ['template', 'save', 'backgroundColor', 'selectedAreaRef', 't'],
  props: {
    field: {
      type: Object,
      required: true
    },
    defaultField: {
      type: Object,
      required: false,
      default: null
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    }
  },
  emits: ['set-draw', 'remove', 'scroll-to'],
  data () {
    return {
      isNameFocus: false,
      showPaymentModal: false,
      isShowFormulaModal: false,
      isShowConditionsModal: false,
      isShowDescriptionModal: false,
      renderDropdown: false
    }
  },
  computed: {
    fieldNames: FieldType.computed.fieldNames,
    dropdownBgColor () {
      return ['', null, 'transparent'].includes(this.backgroundColor) ? 'white' : this.backgroundColor
    },
    schemaAttachmentsIndexes () {
      return (this.template.schema || []).reduce((acc, item, index) => {
        acc[item.attachment_uuid] = index

        return acc
      }, {})
    },
    sortedAreas () {
      return (this.field.areas || []).sort((a, b) => {
        return this.schemaAttachmentsIndexes[a.attachment_uuid] - this.schemaAttachmentsIndexes[b.attachment_uuid]
      })
    },
    modalContainerEl () {
      return this.$el.getRootNode().querySelector('#docuseal_modal_container')
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
    defaultName () {
      return this.buildDefaultName(this.field, this.template.fields)
    },
    areas () {
      return this.field.areas || []
    }
  },
  created () {
    this.field.preferences ||= {}

    if (this.field.type === 'date') {
      this.field.preferences.format ||=
        (Intl.DateTimeFormat().resolvedOptions().locale.endsWith('-US') ? 'MM/DD/YYYY' : 'DD/MM/YYYY')
    }
  },
  methods: {
    buildDefaultName (field, fields) {
      if (field.type === 'payment' && field.preferences?.price) {
        const { price, currency } = field.preferences || {}

        const formattedPrice = new Intl.NumberFormat([], {
          style: 'currency',
          currency
        }).format(price)

        return `${this.fieldNames[field.type]} ${formattedPrice}`
      } else {
        const typeIndex = fields.filter((f) => f.type === field.type).indexOf(field)

        const suffix = { multiple: this.t('select'), radio: this.t('group') }[field.type] || this.t('field')

        return `${this.fieldNames[field.type]} ${suffix} ${typeIndex + 1}`
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

      this.$nextTick(() => {
        this.$emit('scroll-to', this.field.areas[this.field.areas.length - 1])
      })

      this.save()
    },
    onNameFocus (e) {
      this.isNameFocus = true

      if (!this.field.name) {
        setTimeout(() => {
          this.$refs.name.$refs.contenteditable.innerText = ' '
        }, 1)
      }
    },
    maybeFocusOnOptionArea (option) {
      const area = this.field.areas.find((a) => a.option_uuid === option.uuid)

      if (area) {
        this.selectedAreaRef.value = area
      }
    },
    scrollToFirstArea () {
      return this.sortedAreas[0] && this.$emit('scroll-to', this.sortedAreas[0])
    },
    closeDropdown () {
      document.activeElement.blur()
    },
    addOption () {
      this.field.options.push({ value: '', uuid: v4() })

      this.$nextTick(() => {
        const inputs = this.$refs.options.querySelectorAll('input')

        inputs[inputs.length - 1]?.focus()
      })

      this.save()
    },
    removeOption (option) {
      this.field.options.splice(this.field.options.indexOf(option), 1)

      const optionIndex = this.field.areas.findIndex((a) => a.option_uuid === option.uuid)

      if (optionIndex !== -1) {
        this.field.areas.splice(this.field.areas.findIndex((a) => a.option_uuid === option.uuid), 1)
      }

      this.save()
    },
    maybeUpdateOptions () {
      delete this.field.default_value

      if (!['radio', 'multiple', 'select'].includes(this.field.type)) {
        delete this.field.options
      }

      if (['radio', 'multiple', 'select'].includes(this.field.type)) {
        this.field.options ||= [{ value: '', uuid: v4() }]
      }

      (this.field.areas || []).forEach((area) => {
        if (this.field.type === 'cells') {
          area.cell_w = area.w * 2 / Math.floor(area.w / area.h)
        } else {
          delete area.cell_w
        }
      })
    },
    onNameBlur (e) {
      const text = this.$refs.name.$refs.contenteditable.innerText.trim()

      if (text) {
        this.field.name = text
      } else {
        this.field.name = ''
        this.$refs.name.$refs.contenteditable.innerText = this.defaultName
      }

      this.isNameFocus = false

      this.save()
    },
    removeArea (area) {
      this.field.areas.splice(this.field.areas.indexOf(area), 1)

      this.save()
    }
  }
}
</script>
