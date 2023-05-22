<template>
  <div
    class="flex"
    style="max-height: calc(100vh - 24px)"
  >
    <div
      class="overflow-auto w-full"
      style="max-width: 280px"
    >
      Show documents preview (not pages but documents)
      Allow to edit name
      Allow to reorder
      {{ flow.schema }}
      <Upload
        :flow-id="flow.id"
        @success="updateFromUpload"
      />
      <button
        class="bg-green-300"
        @click="save"
      >
        Save changes
      </button>

      <a
        :href="`/flows/${flow.id}/submissions`"
      >
        Add Recepients
      </a>
    </div>
    <div class="w-full overflow-auto">
      <Document
        v-for="document in sortedDocuments"
        :key="document.uuid"
        :areas-index="fieldAreasIndex[document.uuid]"
        :document="document"
        :is-draw="!!drawField"
        :is-drag="!!dragFieldType"
        @draw="onDraw"
        @drop-field="onDropfield"
      />
    </div>
    <div
      class="w-full relative"
      :class="drawField ? 'overflow-hidden' : 'overflow-auto'"
      style="max-width: 280px"
    >
      <div
        v-if="drawField"
        class="sticky inset-0 bg-white h-full"
      >
        Draw {{ drawField.name }} field on the page
        <button @click="drawField = false">
          Cancel
        </button>
      </div>
      <div>
        FIelds
        <Fields
          ref="fields"
          v-model:fields="flow.fields"
          @set-draw="drawField = $event"
          @set-drag="dragFieldType = $event"
          @drag-end="dragFieldType = null"
        />
      </div>
    </div>
  </div>
</template>

<script>
import Upload from './upload'
import Fields from './fields'
import Document from './document'

export default {
  name: 'FlowBuilder',
  components: {
    Upload,
    Document,
    Fields
  },
  props: {
    dataFlow: {
      type: String,
      default: '{}'
    }
  },
  data () {
    return {
      drawField: null,
      dragFieldType: null,
      flow: {
        name: '',
        schema: [],
        documents: [],
        fields: []
      }
    }
  },
  computed: {
    fieldAreasIndex () {
      const areas = {}

      this.flow.fields.forEach((f) => {
        (f.areas || []).forEach((a) => {
          areas[a.attachment_uuid] ||= {}

          const acc = (areas[a.attachment_uuid][a.page] ||= [])

          acc.push({ area: a, field: f })
        })
      })

      return areas
    },
    sortedDocuments () {
      return this.flow.schema.map((item) => {
        return this.flow.documents.find(doc => doc.uuid === item.attachment_uuid)
      })
    }
  },
  mounted () {
    this.flow = JSON.parse(this.dataFlow)

    document.addEventListener('keyup', this.disableDrawOnEsc)
  },
  unmounted () {
    document.removeEventListener('keyup', this.disableDrawOnEsc)
  },
  methods: {
    disableDrawOnEsc (e) {
      if (e.code === 'Escape') {
        this.drawField = null
      }
    },
    onDraw (area) {
      this.drawField.areas ||= []
      this.drawField.areas.push(area)

      this.drawField = null
    },
    onDropfield (area) {
      this.$refs.fields.addField(this.dragFieldType, area)
    },
    updateFromUpload ({ schema, documents }) {
      this.flow.schema.push(...schema)
      this.flow.documents.push(...documents)

      this.save()
    },
    save () {
      return fetch(`/api/flows/${this.flow.id}`, {
        method: 'PUT',
        body: JSON.stringify({ flow: this.flow }),
        headers: { 'Content-Type': 'application/json' }
      }).then((resp) => {
        console.log(resp)
      })
    }
  }
}
</script>
