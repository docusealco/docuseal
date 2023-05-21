import FlowArea from './elements/flow_area'
import FlowView from './elements/flow_view'
import DisableHidden from './elements/disable_hidden'
import FileDropzone from './elements/file_dropzone'
import SignaturePad from './elements/signature_pad'
import FilesList from './elements/files_list'

window.customElements.define('flow-view', FlowView)
window.customElements.define('flow-area', FlowArea)
window.customElements.define('disable-hidden', DisableHidden)
window.customElements.define('file-dropzone', FileDropzone)
window.customElements.define('signature-pad', SignaturePad)
window.customElements.define('files-list', FilesList)
