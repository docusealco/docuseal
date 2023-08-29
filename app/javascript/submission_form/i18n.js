const en = {
  submit_form: 'Submit Form',
  type_here: 'Type here',
  optional: 'optional',
  select_your_option: 'Select your option',
  complete_hightlighted_checkboxes_and_click: 'Complete hightlighted checkboxes and click',
  submit: 'submit',
  next: 'next',
  click_to_upload: 'Click to upload',
  or_drag_and_drop_files: 'or drag and drop files',
  send_copy_via_email: 'Send copy via email',
  download: 'Download',
  form_has_been_completed: 'Form has been completed!',
  create_a_free_account: 'Create a Free Account',
  signed_with: 'Signed with',
  open_source_documents_software: 'open source documents software'
}

const es = {
  submit_form: 'Enviar Formulario',
  type_here: 'Escribe aquí',
  optional: 'opcional',
  select_your_option: 'Selecciona tu opción',
  complete_hightlighted_checkboxes_and_click: 'Completa las casillas resaltadas y haz clic',
  submit: 'enviar',
  next: 'siguiente',
  click_to_upload: 'Haz clic para cargar',
  or_drag_and_drop_files: 'o arrastra y suelta archivos',
  send_copy_via_email: 'Enviar copia por correo electrónico',
  download: 'Descargar',
  form_has_been_completed: '¡El formulario ha sido completado!',
  create_a_free_account: 'Crear una Cuenta Gratuita',
  signed_with: 'Firmado con',
  open_source_documents_software: 'software de documentos de código abierto'
}

const it = {
  submit_form: 'Invia Modulo',
  type_here: 'Digita qui',
  optional: 'opzionale',
  select_your_option: 'Seleziona la tua opzione',
  complete_hightlighted_checkboxes_and_click: 'Completa le caselle evidenziate e fai clic',
  submit: 'invia',
  next: 'avanti',
  click_to_upload: 'Clicca per caricare',
  or_drag_and_drop_files: 'oppure trascina e rilascia i file',
  send_copy_via_email: 'Invia copia via email',
  download: 'Scarica',
  form_has_been_completed: 'Il modulo è stato completato!',
  create_a_free_account: 'Crea un Account Gratuito',
  signed_with: 'Firmato con',
  open_source_documents_software: 'software di documenti open source'
}

const de = {
  submit_form: 'Formular absenden',
  type_here: 'Hier eingeben',
  optional: 'optional',
  select_your_option: 'Wähle deine Option',
  complete_hightlighted_checkboxes_and_click: 'Markierte Kontrollkästchen ausfüllen und klicken',
  submit: 'absenden',
  next: 'weiter',
  click_to_upload: 'Klicken zum Hochladen',
  or_drag_and_drop_files: 'oder Dateien hierher ziehen und ablegen',
  send_copy_via_email: 'Kopie per E-Mail senden',
  download: 'Herunterladen',
  form_has_been_completed: 'Formular wurde ausgefüllt!',
  create_a_free_account: 'Kostenloses Konto erstellen',
  signed_with: 'Unterschrieben mit',
  open_source_documents_software: 'Open-Source-Dokumentensoftware'
}

const fr = {
  submit_form: 'Envoyer le Formulaire',
  type_here: 'Tapez ici',
  optional: 'facultatif',
  select_your_option: 'Sélectionnez votre option',
  complete_hightlighted_checkboxes_and_click: 'Complétez les cases à cocher en surbrillance et cliquez',
  submit: 'envoyer',
  next: 'suivant',
  click_to_upload: 'Cliquez pour télécharger',
  or_drag_and_drop_files: 'ou faites glisser-déposer les fichiers',
  send_copy_via_email: 'Envoyer une copie par e-mail',
  download: 'Télécharger',
  form_has_been_completed: 'Le formulaire a été complété !',
  create_a_free_account: 'Créer un Compte Gratuit',
  signed_with: 'Signé avec',
  open_source_documents_software: 'logiciel de documents open source'
}

const pl = {
  submit_form: 'Wyślij Formularz',
  type_here: 'Wpisz tutaj',
  optional: 'opcjonalny',
  select_your_option: 'Wybierz swoją opcję',
  complete_hightlighted_checkboxes_and_click: 'Wypełnij zaznaczone pola wyboru i kliknij',
  submit: 'wyślij',
  next: 'dalej',
  click_to_upload: 'Kliknij, aby przesłać',
  or_drag_and_drop_files: 'lub przeciągnij i upuść pliki',
  send_copy_via_email: 'Wyślij kopię drogą mailową',
  download: 'Pobierz',
  form_has_been_completed: 'Formularz został wypełniony!',
  create_a_free_account: 'Utwórz darmowe konto',
  signed_with: 'Podpisane za pomocą',
  open_source_documents_software: 'oprogramowanie do dokumentów open source'
}

const uk = {
  submit_form: 'Надіслати Форму',
  type_here: 'Введіть тут',
  optional: 'необов’язково',
  select_your_option: 'Виберіть свій варіант',
  complete_hightlighted_checkboxes_and_click: 'Заповніть позначені прапорці та натисніть',
  submit: 'надіслати',
  next: 'далі',
  click_to_upload: 'Клацніть, щоб завантажити',
  or_drag_and_drop_files: 'або перетягніть файли сюди',
  send_copy_via_email: 'Надіслати копію електронною поштою',
  download: 'Завантажити',
  form_has_been_completed: 'Форму заповнено!',
  create_a_free_account: 'Створити безкоштовний обліковий запис',
  signed_with: 'Підписано за допомогою',
  open_source_documents_software: 'відкритий програмний засіб для документів'
}

const i18n = { en, es, it, de, fr, pl, uk }

const browserLanguage = (navigator.language || navigator.userLanguage || 'en').split('-')[0]

const t = (key) => i18n[browserLanguage][key] || i18n.en[key] || key

export default i18n
export { t }
