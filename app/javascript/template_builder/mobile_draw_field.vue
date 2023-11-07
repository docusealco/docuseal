<template>
  <div class="fixed text-center w-full bottom-0 pr-6 mb-4">
    <span class="w-full bg-base-200 px-4 py-2 rounded-md inline-flex space-x-2 mx-auto items-center justify-between mb-2 z-20 md:hidden">
      <div class="flex items-center space-x-2">
        <component
          :is="fieldIcons[drawField.type]"
          :width="20"
          :height="20"
          class="inline"
          :stroke-width="1.6"
        />
        <span> Draw {{ fieldNames[drawField.type] }} Field </span>
      </div>
      <a
        href="#"
        class="link block text-center"
        @click.prevent="$emit('cancel')"
      >
        Cancel
      </a>
    </span>
    <FieldSubmitter
      :model-value="selectedSubmitter.uuid"
      :submitters="submitters"
      :editable="editable"
      :mobile-view="true"
      @new-submitter="save"
      @remove="removeSubmitter"
      @name-change="save"
      @update:model-value="$emit('change-submitter', submitters.find((s) => s.uuid === $event))"
    />
  </div>
</template>

<script>
import Field from './field'
import FieldType from './field_type'
import FieldSubmitter from './field_submitter'

export default {
  name: 'MobileDrawField',
  components: {
    Field,
    FieldSubmitter
  },
  inject: ['save'],
  props: {
    drawField: {
      type: Object,
      required: true
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    submitters: {
      type: Array,
      required: true
    },
    fields: {
      type: Array,
      required: true
    },
    selectedSubmitter: {
      type: Object,
      required: true
    }
  },
  emits: ['change-submitter', 'cancel'],
  computed: {
    fieldNames: FieldType.computed.fieldNames,
    fieldIcons: FieldType.computed.fieldIcons
  },
  methods: {
    removeSubmitter (submitter) {
      [...this.fields].forEach((field) => {
        if (field.submitter_uuid === submitter.uuid) {
          this.removeField(field)
        }
      })

      this.submitters.splice(this.submitters.indexOf(submitter), 1)

      if (this.selectedSubmitter === submitter) {
        this.$emit('change-submitter', this.submitters[0])
      }

      this.save()
    },
    removeField (field) {
      this.fields.splice(this.fields.indexOf(field), 1)

      this.save()
    }
  }
}
</script>
