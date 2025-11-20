export default class extends HTMLElement {
  async connectedCallback () {
    this.tourType = this.dataset.type
    this.nextPagePath = this.dataset.nextPagePath
    this.I18n = JSON.parse(this.dataset.i18n || '{}')

    if (this.dataset.showTour === 'true') this.start()
  }

  async start () {
    if (window.innerWidth < 768) return

    const [{ driver }] = await Promise.all([
      import('driver.js'),
      import('driver.js/dist/driver.css')
    ])

    this.driverObj = driver({
      showProgress: true,
      nextBtnText: this.I18n.next,
      prevBtnText: this.I18n.previous,
      doneBtnText: this.I18n.done,
      onDestroyStarted: () => {
        this.disableAppGuide().finally(() => { this.destroy() })
      },
      onHighlightStarted: (element) => {
        if (element) {
          const clickHandler = () => {
            this.disableAppGuide().finally(() => { this.destroy() })
            element.removeEventListener('click', clickHandler)
          }

          element.addEventListener('click', clickHandler)
        }
      }
    })

    if (this.tourType === 'dashboard') {
      this.showDashboardTour()
    } else if (this.tourType === 'builder') {
      this.showTemplateBuilderTour()
    } else if (this.tourType === 'account') {
      this.showAccountTour()
    } else if (this.tourType === 'template') {
      this.showTemplateTour()
    }
  }

  disconnectedCallback () {
    if (this.driverObj) this.destroy()
  }

  destroy () {
    if (this.builderTemplate) this.builderTemplate.fields.shift()
    if (this.driverObj) this.driverObj.destroy()
  }

  showTemplateTour () {
    const steps = [
      {
        element: '#share_link_clipboard',
        popover: {
          title: this.I18n.copy_and_share_link,
          description: this.I18n.copy_and_share_link_description,
          side: 'bottom',
          align: 'end'
        }
      },
      {
        element: '#sign_yourself_button',
        popover: {
          title: this.I18n.sign_the_document,
          description: this.I18n.sign_the_document_description,
          side: 'top',
          align: 'center'
        }
      },
      {
        element: '#send_to_recipients_button',
        popover: {
          title: this.I18n.send_for_signing,
          description: this.I18n.add_recipients_description,
          side: 'top',
          align: 'center'
        }
      },
      {
        element: '#add_recipients_button',
        popover: {
          title: this.I18n.add_recipients,
          description: this.I18n.add_recipients_description,
          side: 'bottom',
          align: 'end'
        }
      },
      {
        element: '#account_settings_button',
        popover: {
          title: this.I18n.settings,
          description: this.I18n.settings_template_description,
          side: 'right',
          align: 'start',
          showButtons: this.nextPagePath ? ['next', 'previous', 'close'] : ['previous', 'close'],
          onNextClick: () => {
            if (this.nextPagePath) {
              window.Turbo.visit(this.nextPagePath)
            }
          }
        }
      }
    ].filter((step) => document.querySelector(step.element))

    this.driverObj.setSteps(steps)
    this.driverObj.drive()
  }

  showDashboardTour () {
    this.driverObj.setSteps([
      {
        element: '#templates_submissions_toggle',
        popover: {
          title: this.I18n.template_and_submissions,
          description: this.I18n.template_and_submissions_description,
          side: 'right',
          align: 'start'
        }
      },
      {
        element: '#templates_upload_button',
        popover: {
          title: this.I18n.upload_a_pdf_file,
          description: this.I18n.upload_a_pdf_file_description,
          side: 'left',
          align: 'start',
          showButtons: this.nextPagePath ? ['next', 'previous', 'close'] : ['previous', 'close'],
          onNextClick: () => {
            if (this.nextPagePath) {
              window.Turbo.visit(this.nextPagePath)
            }
          }
        },
        onHighlightStarted: () => {}
      }
    ])

    this.driverObj.drive()
  }

  showAccountTour () {
    this.driverObj.setSteps([
      {
        element: '#account_settings_menu',
        popover: {
          title: this.I18n.settings,
          description: this.I18n.settings_account_description,
          side: 'right',
          align: 'start'
        }
      },
      {
        element: '#support_channels',
        popover: {
          title: this.I18n.support,
          description: this.I18n.support_description,
          side: 'left',
          align: 'start'
        }
      }
    ].filter((step) => document.querySelector(step.element)))

    this.driverObj.drive()
  }

  showTemplateBuilderTour () {
    const builderComponent = document.querySelector('template-builder')?.component

    this.builderTemplate = builderComponent?.template

    if (this.builderTemplate) {
      this.builderTemplate.fields.unshift({
        uuid: 'b387399b-88dc-4345-9d37-743e97a9b2b3',
        submitter_uuid: this.builderTemplate.submitters[0].uuid,
        name: 'First Name',
        type: 'text'
      })

      builderComponent.$nextTick(() => {
        this.driverObj.setSteps([
          {
            element: '.roles-dropdown',
            popover: {
              title: this.I18n.select_a_signer_party,
              description: this.I18n.select_a_signer_party_description,
              side: 'left',
              align: 'start',
              onPopoverRender: () => {
                const rolesDropdown = document.querySelector('.roles-dropdown')

                rolesDropdown.dispatchEvent(new Event('mouseenter', { bubbles: true, cancelable: true }))
                rolesDropdown.classList.add('dropdown-open')
              }
            }
          },
          {
            element: '.roles-dropdown .dropdown-content',
            popover: {
              title: this.I18n.available_parties,
              description: this.I18n.available_parties_description,
              side: 'left',
              align: 'start',
              onPopoverRender: () => {
                document.querySelector('.roles-dropdown .dropdown-content').classList.remove('driver-active-element')
              },
              onNextClick: () => {
                document.querySelector('.roles-dropdown').classList.remove('dropdown-open')
                this.driverObj.moveNext()
              }
            }
          },
          {
            element: '#field-types-grid',
            popover: {
              title: this.I18n.available_field_types,
              description: this.I18n.available_field_types_description,
              side: 'right',
              align: 'start',
              onPrevClick: () => {
                document.querySelector('.roles-dropdown').classList.add('dropdown-open')
                this.driverObj.movePrevious()
              }
            }
          },
          {
            element: '#text_type_field_button',
            popover: {
              title: this.I18n.text_input_field,
              description: this.I18n.text_input_field_description,
              side: 'left',
              align: 'start'
            }
          },
          {
            element: '#signature_type_field_button',
            popover: {
              title: this.I18n.signature_field,
              description: this.I18n.signature_field_description,
              side: 'left',
              align: 'start'
            }
          },
          {
            element: '.fields',
            popover: {
              title: this.I18n.added_fields,
              description: this.I18n.added_fields_description,
              side: 'right',
              align: 'start'
            }
          },
          {
            element: '.list-field label:has(svg.tabler-icon-settings)',
            popover: {
              title: this.I18n.open_field_settings,
              description: this.I18n.open_field_settings_description,
              side: 'bottom',
              align: 'end',
              onPopoverRender: () => {
                const settingsDropdown = document.querySelector('.list-field div:first-child span:has(svg.tabler-icon-settings)')

                document.querySelectorAll('.list-field div:first-child .text-transparent').forEach((e) => e.classList.remove('text-transparent'))
                settingsDropdown.dispatchEvent(new Event('mouseenter', { bubbles: true, cancelable: true }))
                settingsDropdown.classList.add('dropdown-open')
              }
            }
          },
          {
            element: '.list-field div:first-child span:has(svg.tabler-icon-settings) .dropdown-content',
            popover: {
              title: this.I18n.field_settings,
              description: this.I18n.field_settings_description,
              side: 'left',
              align: 'start',
              onPopoverRender: () => {
                document.querySelector('.list-field div:first-child span:has(svg.tabler-icon-settings) .dropdown-content').classList.remove('driver-active-element')
              },
              onNextClick: () => {
                document.querySelector('.list-field div:first-child span:has(svg.tabler-icon-settings)').classList.remove('dropdown-open')
                this.driverObj.moveNext()
              }
            }
          },
          {
            element: '#send_button',
            popover: {
              title: this.I18n.send_document,
              description: this.I18n.send_document_description,
              side: 'bottom',
              align: 'end',
              onPrevClick: () => {
                document.querySelector('.list-field div:first-child span:has(svg.tabler-icon-settings)').classList.add('dropdown-open')
                this.driverObj.movePrevious()
              }
            }
          },
          {
            element: '#sign_yourself_button',
            popover: {
              title: this.I18n.sign_yourself,
              description: this.I18n.sign_yourself_description,
              side: 'bottom',
              align: 'end',
              onNextClick: () => {
                if (this.nextPagePath) {
                  window.Turbo.visit(this.nextPagePath)
                } else {
                  this.destroy()
                }
              }
            }
          }
        ])

        this.driverObj.drive()
      })
    }
  }

  async disableAppGuide () {
    return fetch('/user_configs', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ key: 'show_app_tour', value: false })
    })
  }
}
