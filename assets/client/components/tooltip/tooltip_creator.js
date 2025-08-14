import tooltipHtml from './tooltip.html';
import { createElement } from '../../utils/dom';

function populateTypeInfo(tooltip, data) {
  const typeInfo = tooltip.querySelector('.type-info');
  const typeText = typeInfo.querySelector('.type-text');
  const typeSquare = typeInfo.querySelector('.live-debugger-type-square');

  typeText.textContent = data.type;
  typeSquare.style.backgroundColor =
    data.type === 'LiveComponent' ? '#87CCE8' : '#ffe780';
}

function populateIdInfo(tooltip, data) {
  const idInfo = tooltip.querySelector('.id-info');
  const label = idInfo.querySelector('.label');
  const value = idInfo.querySelector('.value');

  label.textContent = `${data.id_key}:`;
  value.textContent = data.id_value;
}

function populateInfoSection(tooltip, data) {
  populateTypeInfo(tooltip, data);
  populateIdInfo(tooltip, data);
}

function setModuleName(tooltip, data) {
  const moduleName = tooltip.querySelector('.live-debugger-tooltip-module');
  moduleName.textContent = data.module || 'Element';
}

export function createTooltip(data) {
  const tooltip = createElement(tooltipHtml);

  setModuleName(tooltip, data);
  populateInfoSection(tooltip, data);

  document.body.appendChild(tooltip);
  return tooltip;
}
