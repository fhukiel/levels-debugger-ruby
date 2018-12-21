'use babel';

import Breakpoint             from './breakpoint';
import levelsWorkspaceManager from './levels-workspace-manager';
import {fromPoint, toPoint}   from './position-utils';

class BreakpointManager {
  constructor() {
    this.breakPoints = [];
    this.areBreakpointsEnabled = true;
    this.hiddenBreakpointPosition = null;
  }

  getAreBreakpointsEnabled() {
    return this.areBreakpointsEnabled;
  }

  getBreakpoints() {
    return this.breakPoints;
  }

  removeAll() {
    for (const bp of this.breakPoints) {
      bp.destroyMarker();
    }

    this.breakPoints = [];
  }

  flip() {
    this.areBreakpointsEnabled = !this.areBreakpointsEnabled;
    for (const bp of this.breakPoints) {
      if (bp.hasMarker()) {
        bp.destroyMarker();
        bp.setMarker(levelsWorkspaceManager.addBreakpointMarker(toPoint(bp.getPosition()), this.areBreakpointsEnabled));
      }
    }
  }

  toggle(point) {
    const breakPointPosition = fromPoint(point);
    const existingBreakpoint = this.getBreakpoint(breakPointPosition);

    if (existingBreakpoint) {
      this.breakPoints = this.breakPoints.filter((bp) => bp !== existingBreakpoint);
      existingBreakpoint.destroyMarker();

      return false;
    } else {
      const marker = levelsWorkspaceManager.addBreakpointMarker(point, this.areBreakpointsEnabled);
      this.breakPoints.push(new Breakpoint(breakPointPosition, marker));

      return true;
    }
  }

  getBreakpoint(position) {
    for (const bp of this.breakPoints) {
      if (bp.getPosition().isOnSameLine(position)) {
        return bp;
      }
    }
  }

  hideBreakpoint(position) {
    if (!this.hiddenBreakpointPosition || !position.isOnSameLine(this.hiddenBreakpointPosition)) {
      const breakpoint = this.getBreakpoint(position);
      if (breakpoint) {
        breakpoint.destroyMarker();
        this.hiddenBreakpointPosition = breakpoint.getPosition();
      }
    }
  }

  restoreHiddenBreakpoint() {
    if (this.hiddenBreakpointPosition) {
      const existingBreakpoint = this.getBreakpoint(this.hiddenBreakpointPosition);
      if (existingBreakpoint) {
        const marker = levelsWorkspaceManager.addBreakpointMarker(toPoint(this.hiddenBreakpointPosition), this.areBreakpointsEnabled);
        existingBreakpoint.setMarker(marker);
      }
    }

    this.hiddenBreakpointPosition = null;
  }
}

export default new BreakpointManager();