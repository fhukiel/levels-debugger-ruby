'use babel';

import {Point}  from 'atom';
import Position from './position';

export function fromPoint(point) {
  return new Position(point.row + 1, point.column);
}

export function toPoint(position) {
  return new Point(position.getLine() - 1, position.getColumn());
}