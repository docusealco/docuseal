<template>
  <div>
    <div v-if="selectedSheetIndex === null && spreadsheet">
      <form @submit.prevent="[selectedSheetIndex = $refs.selectWorksheet.value, buildDefaultMappings()]">
        <label class="label">
          Select Worksheet
        </label>
        <select
          ref="selectWorksheet"
          class="base-select"
        >
          <option
            v-for="(sheet, index) in spreadsheet"
            :key="index"
            :value="index"
          >
            {{ sheet[0] || index }}
          </option>
        </select>
        <button class="base-button mt-4 w-full">
          Open
        </button>
      </form>
    </div>
    <div v-else-if="selectedSheetIndex !== null">
      <div
        v-for="submitter in submitters"
        :key="submitter.uuid"
        class="mb-4"
      >
        <div
          v-if="submitters.length > 1"
          class="px-3 border-y py-2 border-base-300 text-center w-full"
        >
          {{ submitter.name }}
        </div>
        <div class="flex">
          <div class="relative w-full py-2 px-2 text-sm">
            Recipient field
          </div>
          <div class="relative w-full py-2 pl-4 text-sm">
            Spreadsheet column
          </div>
        </div>
        <div
          v-for="mapping in mappings.filter((m) => m.submitter_uuid === submitter.uuid)"
          :key="mapping.uuid"
          class="mb-2"
        >
          <div class="flex">
            <select
              class="base-select !select-sm !h-10"
              required
              @change="mapping.field_name = $event.target.value"
            >
              <option
                disabled
                value=""
                :selected="!mapping.field_name"
              >
                Select Field
              </option>
              <option
                v-for="(field, index) in selectFieldsForSubmitter(submitter)"
                :key="index"
                :value="field.name"
                :selected="mapping.field_name === field.name"
              >
                {{ field.name }}
              </option>
            </select>
            <div class="flex items-center px-1">
              <IconArrowsHorizontal style="width: 19px; height: 19px" />
            </div>
            <div class="w-full relative">
              <select
                class="base-select !select-sm !h-10"
                required
                @change="mapping.column_index = parseInt($event.target.value)"
              >
                <option
                  disabled
                  value=""
                  :selected="mapping.column_index == null"
                >
                  Select Column
                </option>
                <template
                  v-for="(column, index) in columns"
                  :key="index"
                >
                  <option
                    v-if="column"
                    :value="index"
                    :selected="index === mapping.column_index"
                  >
                    {{ column }}
                  </option>
                </template>
              </select>
              <div
                v-if="mapping.column_index != null"
                class="absolute top-0 bottom-0 right-1 flex items-center"
              >
                <span
                  class="tooltip tooltip-bottom-end pr-1 tooltip-pre"
                  style="padding-top: 2px"
                  :data-tip="[0, 1, 2].map((i) => rows[i]?.[mapping.column_index] ?? '---').join('\n')"
                >
                  <button
                    class="btn btn-xs btn-circle bg-white border-0 border-gray-300"
                    @click.prevent
                  >
                    <IconInfoCircle class="h-4 w-4" />
                  </button>
                </span>
              </div>
            </div>
            <div class="flex items-center pl-1">
              <span
                class="tooltip tooltip-top"
                data-tip="Remove"
              >
                <button
                  :disabled="mappings.filter((m) => m.submitter_uuid === submitter.uuid).length < 2"
                  class="btn btn-xs btn-circle"
                  @click.prevent="mappings.splice(mappings.indexOf(mapping), 1)"
                >
                  <IconX class="h-3.5 w-3.5" />
                </button>
              </span>
            </div>
          </div>
        </div>
        <div>
          <button
            class="btn btn-sm btn-primary w-full !normal-case font-medium"
            @click.prevent="addMapping(submitter)"
          >
            <IconPlus class="w-4 h-4" />
            New Field Mapping
          </button>
        </div>
      </div>
      <div>
        <input
          name="submissions_json"
          hidden
          :value="multitenant ? JSON.stringify(submissionsData.slice(0, 1100)) : JSON.stringify(submissionsData)"
        >
      </div>
      <div
        class="px-3 border-y py-2 border-base-300 text-center w-full text-sm font-semibold"
      >
        Total entries: {{ submissionsData.length }}
        <template v-if="multitenant && submissionsData.length >= 1000">
          / 1000
        </template>
      </div>
    </div>
    <div
      v-else
    >
      <div
        class="flex h-52 w-full"
        @dragover.prevent
        @drop.prevent="onDropFiles"
      >
        <label
          class="w-full relative bg-base-200/20  hover:bg-base-200/30 rounded-md border border-2 border-base-content/10 border-dashed"
          for="import_list_file"
          :class="{ 'opacity-50': isLoading }"
        >
          <div class="absolute top-0 right-0 left-0 bottom-0 flex items-center justify-center">
            <div class="flex flex-col items-center">
              <IconInnerShadowTop
                v-if="isLoading"
                class="animate-spin"
                :width="40"
                :height="40"
              />
              <IconCloudUpload
                v-else
                :width="40"
                :height="40"
              />
              <div
                class="font-medium text-lg mb-1"
              >
                Upload CSV or XLSX Spreadsheet
              </div>
              <div class="text-sm">
                <span class="font-medium">Click to Upload</span> or drag and drop files.
              </div>
            </div>
          </div>
          <form
            ref="form"
            class="hidden"
          >
            <input
              id="import_list_file"
              ref="input"
              type="file"
              name="file"
              accept=".xlsx, .xls, .csv"
              @change="onSelectFile"
            >
          </form>
        </label>
      </div>
      <div class="text-center mt-2">
        Or <a
          :download="`${template.name}.csv`"
          :href="`data:text/csv;base64,${csvBase64}`"
          class="link font-medium"
        >download</a> a spreadsheet to fill and import
      </div>
    </div>
  </div>
</template>

<script>
import { IconCloudUpload, IconX, IconPlus, IconArrowsHorizontal, IconInfoCircle, IconInnerShadowTop } from '@tabler/icons-vue'
import { v4 } from 'uuid'

export default {
  name: 'FileDropzone',
  components: {
    IconCloudUpload,
    IconX,
    IconArrowsHorizontal,
    IconPlus,
    IconInfoCircle,
    IconInnerShadowTop
  },
  props: {
    template: {
      type: Object,
      required: true
    },
    multitenant: {
      type: Boolean,
      required: false,
      default: false
    },
    authenticityToken: {
      type: String,
      required: false,
      default: ''
    }
  },
  data () {
    return {
      isLoading: false,
      spreadsheet: null,
      selectedSheetIndex: null,
      mappings: []
    }
  },
  computed: {
    table () {
      return this.spreadsheet[this.selectedSheetIndex][1]
    },
    submissionsData () {
      const submissions = []

      this.rows.forEach((row) => {
        const submittersIndex = {}

        this.mappings.forEach((mapping) => {
          if (mapping.field_name && mapping.column_index != null) {
            submittersIndex[mapping.submitter_uuid] ||= { uuid: mapping.submitter_uuid, fields: [] }

            if (['name', 'email', 'phone', 'external_id'].includes(mapping.field_name.toLowerCase())) {
              submittersIndex[mapping.submitter_uuid][mapping.field_name.toLowerCase()] = row[mapping.column_index]
            }

            const fieldType = this.fieldTypesIndex[mapping.submitter_uuid][mapping.field_name]

            if (fieldType && fieldType !== 'phone') {
              submittersIndex[mapping.submitter_uuid].fields.push({
                name: mapping.field_name, default_value: row[mapping.column_index], readonly: true
              })
            }
          }
        })

        if (Object.keys(submittersIndex).length !== 0) {
          submissions.push({ submitters: Object.values(submittersIndex) })
        }
      })

      return submissions
    },
    csvBase64 () {
      const rows = []

      this.submitters.forEach((submitter) => {
        this.selectFieldsForSubmitter(submitter).forEach((field) => {
          rows.push(this.submitters.length > 1 ? `${submitter.name} - ${field.name}` : field.name)
        })
      })

      const csv = rows.map(item => {
        if (/[",\n]/.test(item)) {
          return `"${item.replace(/"/g, '""')}"`
        } else {
          return item
        }
      }).join(',')

      return window.btoa(window.unescape(window.encodeURIComponent(csv + '\n' + rows.map(() => '').join(',') + '\n')))
    },
    submitters () {
      return this.template.submitters
    },
    fieldTypesIndex () {
      return this.template.fields.reduce((acc, field) => {
        acc[field.submitter_uuid] ||= {}

        if (field.name) {
          acc[field.submitter_uuid][field.name] = field.type
        }

        return acc
      }, {})
    },
    columns () {
      return this.table[0]
    },
    form () {
      return this.$el.closest('form')
    },
    fieldTypes () {
      return ['text', 'cells', 'date', 'number', 'radio', 'select', 'checkbox']
    },
    defaultFields () {
      return [
        { name: 'Name' },
        { name: 'Email' },
        { name: 'Phone' }
      ]
    },
    rows () {
      return this.table.slice(1)
    }
  },
  watch: {
    selectedSheetIndex (value) {
      if (value !== null) {
        document.getElementById('list_form_buttons')?.classList?.remove('hidden')
      }
    }
  },
  methods: {
    onDropFiles (e) {
      this.uploadFile(e.dataTransfer.files[0])
    },
    onSelectFile (e) {
      this.uploadFile(e.target.files[0])
    },
    addMapping (submitter) {
      this.mappings.push({ uuid: v4(), field_name: '', column_index: null, submitter_uuid: submitter.uuid })
    },
    selectFieldsForSubmitter (submitter) {
      const templateFields = this.template.fields.filter((field) => {
        return field.submitter_uuid === submitter.uuid &&
          field.name &&
          this.fieldTypes.includes(field.type) &&
          this.defaultFields.every((f) => field.name?.toLowerCase() !== f.name?.toLowerCase())
      })

      const fields = [...this.defaultFields, ...templateFields]

      if (this.spreadsheet && this.columns.includes('external_id')) {
        fields.push({ name: 'external_id' })
      }

      return fields
    },
    buildDefaultMappings () {
      this.submitters.forEach((submitter) => {
        const fields = this.selectFieldsForSubmitter(submitter)

        fields.forEach((field) => {
          const columnIndex = this.columns.findIndex((column, index) => {
            return column &&
              column.toString().toLowerCase().includes(field.name?.toLowerCase()) &&
              this.mappings.every((m) => m.column_index !== index)
          })

          if (columnIndex !== -1) {
            this.mappings.push({ uuid: v4(), field_name: field.name, column_index: columnIndex, submitter_uuid: submitter.uuid })
          }
        })

        if (!this.mappings.some((m) => m.field_name.toLowerCase() === 'name' && m.submitter_uuid === submitter.uuid)) {
          this.mappings.unshift({ uuid: v4(), field_name: 'Name', submitter_uuid: submitter.uuid })
        }

        if (!this.mappings.some((m) => m.field_name.toLowerCase() === 'email' && m.submitter_uuid === submitter.uuid)) {
          this.mappings.unshift({ uuid: v4(), field_name: 'Email', submitter_uuid: submitter.uuid })
        }
      })
    },
    uploadFile (file) {
      this.isLoading = true

      const formData = new FormData()

      formData.append('file', file)

      return fetch('/upload_spreadsheet', {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': this.authenticityToken
        }
      }).then(resp => resp.json()).then((data) => {
        if (data.error) {
          return alert(data.error)
        }

        this.spreadsheet = data

        if (data.length === 1) {
          this.selectedSheetIndex = 0

          this.buildDefaultMappings()
        }
      }).finally(() => {
        this.isLoading = false
      })
    }
  }
}
</script>
