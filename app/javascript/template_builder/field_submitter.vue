<template>
  <div v-if="mobileView">
    <div class="flex space-x-2 items-end">
      <div class="group/contenteditable-container bg-base-100 rounded-md p-2 border border-base-300 w-full flex justify-between items-end">
        <div class="flex items-center space-x-2">
          <span
            class="w-3 h-3 flex-shrink-0 rounded-full"
            :class="colors[submitters.indexOf(selectedSubmitter)]"
          />
          <Contenteditable
            v-model="selectedSubmitter.name"
            class="cursor-text"
            :icon-inline="true"
            :editable="editable"
            :select-on-edit-click="true"
            :icon-width="18"
            @update:model-value="$emit('name-change', selectedSubmitter)"
          />
        </div>
      </div>
      <div class="dropdown dropdown-top dropdown-end">
        <label
          tabindex="0"
          class="bg-base-100 cursor-pointer rounded-md p-2 border border-base-300 w-full flex justify-center"
        >
          <IconChevronUp
            width="24"
            height="24"
          />
        </label>
        <ul
          v-if="editable"
          tabindex="0"
          class="rounded-md min-w-max mb-2"
          :class="menuClasses"
          @click="closeDropdown"
        >
          <li
            v-for="(submitter, index) in submitters"
            :key="submitter.uuid"
          >
            <a
              href="#"
              class="flex px-2 group justify-between items-center"
              :class="{ 'active': submitter === selectedSubmitter }"
              @click.prevent="selectSubmitter(submitter)"
            >
              <span class="py-1 flex items-center">
                <span
                  class="rounded-full w-3 h-3 ml-1 mr-3"
                  :class="colors[index]"
                />
                <span>
                  {{ submitter.name }}
                </span>
              </span>
              <button
                v-if="submitters.length > 1 && editable"
                class="px-2"
                @click.stop="remove(submitter)"
              >
                <IconTrashX :width="18" />
              </button>
            </a>
          </li>
          <li v-if="submitters.length < 10 && editable">
            <a
              href="#"
              class="flex px-2"
              @click.prevent="addSubmitter"
            >
              <IconUserPlus
                :width="20"
                :stroke-width="1.6"
              />
              <span class="py-1">
                Add {{ names[submitters.length] }}
              </span>
            </a>
          </li>
        </ul>
      </div>
    </div>
  </div>
  <div
    v-else
    class="dropdown"
  >
    <label
      v-if="compact"
      tabindex="0"
      :title="selectedSubmitter.name"
      class="cursor-pointer text-base-100 flex h-full items-center justify-center"
    >
      <button
        class="mx-1 w-3 h-3 rounded-full"
        :class="colors[submitters.indexOf(selectedSubmitter)]"
      />
    </label>
    <label
      v-else
      tabindex="0"
      class="group cursor-pointer group/contenteditable-container rounded-md p-2 border border-base-300 hover:border-content w-full flex justify-between"
    >
      <div class="flex items-center space-x-2">
        <span
          class="w-3 h-3 rounded-full"
          :class="colors[submitters.indexOf(selectedSubmitter)]"
        />
        <Contenteditable
          v-model="selectedSubmitter.name"
          class="cursor-text"
          :icon-inline="true"
          :editable="editable"
          :select-on-edit-click="true"
          :icon-width="18"
          @update:model-value="$emit('name-change', selectedSubmitter)"
        />
      </div>
      <span class="flex items-center transition-all duration-75 group-hover:border border-base-content/20 border-dashed w-6 h-6 flex justify-center items-center rounded">
        <IconPlus
          width="18"
          height="18"
        />
      </span>
    </label>
    <ul
      v-if="editable || !compact"
      tabindex="0"
      :class="menuClasses"
      @click="closeDropdown"
    >
      <li
        v-for="(submitter, index) in submitters"
        :key="submitter.uuid"
      >
        <a
          href="#"
          class="flex px-2 group justify-between items-center"
          :class="{ 'active': submitter === selectedSubmitter }"
          @click.prevent="selectSubmitter(submitter)"
        >
          <span class="py-1 flex items-center">
            <span
              class="rounded-full w-3 h-3 ml-1 mr-3"
              :class="colors[index]"
            />
            <span>
              {{ submitter.name }}
            </span>
          </span>
          <button
            v-if="!compact && submitters.length > 1 && editable"
            class="hidden group-hover:block px-2"
            @click.stop="remove(submitter)"
          >
            <IconTrashX :width="18" />
          </button>
        </a>
      </li>
      <li v-if="submitters.length < 10 && editable">
        <a
          href="#"
          class="flex px-2"
          @click.prevent="addSubmitter"
        >
          <IconUserPlus
            :width="20"
            :stroke-width="1.6"
          />
          <span class="py-1">
            Add {{ names[submitters.length] }}
          </span>
        </a>
      </li>
    </ul>
  </div>
</template>

<script>
import { IconUserPlus, IconTrashX, IconPlus, IconChevronUp } from '@tabler/icons-vue'
import Contenteditable from './contenteditable'
import { v4 } from 'uuid'

export default {
  name: 'FieldSubmitter',
  components: {
    IconUserPlus,
    Contenteditable,
    IconPlus,
    IconTrashX,
    IconChevronUp
  },
  props: {
    submitters: {
      type: Array,
      required: true
    },
    editable: {
      type: Boolean,
      required: false,
      default: true
    },
    compact: {
      type: Boolean,
      required: false,
      default: false
    },
    mobileView: {
      type: Boolean,
      required: false,
      default: false
    },
    modelValue: {
      type: String,
      required: true
    },
    menuClasses: {
      type: String,
      required: false,
      default: 'dropdown-content menu p-2 shadow bg-base-100 rounded-box w-full z-10'
    }
  },
  emits: ['update:model-value', 'remove', 'new-submitter', 'name-change'],
  computed: {
    colors () {
      return [
        'bg-red-500',
        'bg-sky-500',
        'bg-emerald-500',
        'bg-yellow-300',
        'bg-purple-600',
        'bg-pink-500',
        'bg-cyan-500',
        'bg-orange-500',
        'bg-lime-500',
        'bg-indigo-500'
      ]
    },
    names () {
      return [
        'First Party',
        'Second Party',
        'Third Party',
        'Fourth Party',
        'Fifth Party',
        'Sixth Party',
        'Seventh Party',
        'Eighth Party',
        'Ninth Party',
        'Tenth Party'
      ]
    },
    selectedSubmitter () {
      return this.submitters.find((e) => e.uuid === this.modelValue)
    }
  },
  methods: {
    selectSubmitter (submitter) {
      this.$emit('update:model-value', submitter.uuid)
    },
    remove (submitter) {
      if (window.confirm('Are you sure?')) {
        this.$emit('remove', submitter)
      }
    },
    addSubmitter () {
      const newSubmitter = {
        name: this.names[this.submitters.length],
        uuid: v4()
      }

      this.submitters.push(newSubmitter)

      this.$emit('update:model-value', newSubmitter.uuid)
      this.$emit('new-submitter', newSubmitter)
    },
    closeDropdown () {
      document.activeElement.blur()
    }
  }
}
</script>
