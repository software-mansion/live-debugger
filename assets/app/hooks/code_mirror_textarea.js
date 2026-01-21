import { EditorView, basicSetup } from 'codemirror';
import { elixir } from 'codemirror-lang-elixir';

import { githubLight } from '@fsegurai/codemirror-theme-github-light';
import { githubDark } from '@fsegurai/codemirror-theme-github-dark';

const CodeMirrorTextarea = {
  mounted() {
    const theme = localStorage.getItem('theme');
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

    const extensions = [basicSetup, elixir(), syncToTextarea];
    if (theme === 'dark') {
      extensions.push(githubDark);
    } else {
      extensions.push(githubLight);
    }

    let editor = new EditorView({
      extensions: extensions,
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

    // Prevent clicks inside CodeMirror from propagating to parent elements
    // This prevents collapsible elements (chevrons, three dots) from closing modals
    const stopPropagation = (event) => {
      event.stopPropagation();
    };
    targetDiv.addEventListener('click', stopPropagation);
    this.stopPropagationHandler = stopPropagation;

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
  destroyed() {
    if (this.stopPropagationHandler) {
      const targetDivId = this.el.id.replace('-codearea-wrapper', '-codemirror');
      const targetDiv = document.getElementById(targetDivId);
      if (targetDiv) {
        targetDiv.removeEventListener('click', this.stopPropagationHandler);
      }
    }
  },
};

export default CodeMirrorTextarea;
