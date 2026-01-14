import { EditorView, basicSetup } from 'codemirror';
import { elixir } from 'codemirror-lang-elixir';
import { oneDark } from '@codemirror/theme-one-dark';

const CodeMirrorTextarea = {
  mounted() {
    const targetDivId = this.el.id.replace('-codearea-wrapper', '-codemirror');
    const textareaId = this.el.id.replace('-codearea-wrapper', '');

    const targetDiv = document.getElementById(targetDivId);
    const textarea = document.getElementById(textareaId);

    const syncToTextarea = EditorView.updateListener.of((update) => {
      if (update.docChanged) {
        textarea.value = update.state.doc.toString();

        const inputEvent = new Event('input', { bubbles: true });
        textarea.dispatchEvent(inputEvent);
      }
    });

    let editor = new EditorView({
      extensions: [basicSetup, elixir(), oneDark, syncToTextarea],
      parent: targetDiv,
    });

    if (textarea.value) {
      editor.dispatch({
        changes: {
          from: 0,
          to: editor.state.doc.length,
          insert: textarea.value,
        },
      });
    }

    this.editor = editor;
  },
  updated() {
    const currentTextareaValue = this.el.dataset.value;
    const currentEditorValue = this.editor.state.doc.toString();

    if (currentTextareaValue !== currentEditorValue) {
      this.editor.dispatch({
        changes: {
          from: 0,
          to: this.editor.state.doc.length,
          insert: currentTextareaValue,
        },
      });
    }
  },
};

export default CodeMirrorTextarea;
