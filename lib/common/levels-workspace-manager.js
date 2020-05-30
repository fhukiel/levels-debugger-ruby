'use babel';

import {Emitter} from 'atom';

class LevelsWorkspaceManager {
  constructor() {
    this.emitter = new Emitter();
  }

  destroy() {
    this.emitter.dispose();
  }

  attachWorkspace(levelsWorkspace) {
    if (levelsWorkspace) {
      this.levelsWorkspace = levelsWorkspace;
      this.emitter.emit('workspace-attached', this.levelsWorkspace);
    }
  }

  onWorkspaceAttached(callback) {
    return this.emitter.on('workspace-attached', callback);
  }

  getWorkspace() {
    return this.levelsWorkspace;
  }

  getActiveTerminal() {
    return this.levelsWorkspace.getActiveTerminal();
  }

  getActiveLevelCodeEditor() {
    return this.levelsWorkspace.getActiveLevelCodeEditor();
  }

  getActiveTextEditor() {
    const levelEditor = this.getActiveLevelCodeEditor();
    if (levelEditor) {
      return levelEditor.getTextEditor();
    }
  }

  getActiveLanguage() {
    return this.levelsWorkspace.getActiveLanguage();
  }

  isActiveLanguageRuby() {
    const activeLanguage = this.getActiveLanguage();
    if (activeLanguage) {
      return activeLanguage.getName() === 'Ruby';
    }

    return false;
  }

  getActiveLevel() {
    return this.levelsWorkspace.getActiveLevel();
  }

  isActiveLevelDebuggable() {
    const activeLevel = this.getActiveLevel();
    if (activeLevel) {
      const isDebuggable = activeLevel.getOption('debuggable');

      return isDebuggable !== null && isDebuggable && this.isActiveLanguageRuby();
    }

    return false;
  }

  isActive() {
    return this.levelsWorkspace.isActive();
  }

  getActiveTextEditorCursorPositions() {
    const textEditor = this.getActiveTextEditor();
    if (textEditor) {
      return textEditor.getCursorBufferPositions();
    }
  }

  addBreakpointMarker(point, enabled) {
    const textEditor = this.getActiveTextEditor();
    if (textEditor) {
      const marker = textEditor.markBufferPosition(point, {invalidate: 'inside'});
      const className = enabled ? 'annotation annotation-breakpoint' : 'annotation annotation-breakpoint-disabled';
      textEditor.decorateMarker(marker, {type: 'line-number', class: className});

      return marker;
    }
  }

  addPositionMarker(point) {
    const textEditor = this.getActiveTextEditor();
    if (textEditor) {
      const marker = textEditor.markBufferPosition(point, {invalidate: 'inside'});
      textEditor.decorateMarker(marker, {type: 'line-number', class: 'annotation annotation-position'});

      return marker;
    }
  }
}

export default new LevelsWorkspaceManager();