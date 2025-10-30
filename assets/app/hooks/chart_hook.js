import Chart from 'chart.js/auto';

const MAX_DATA_POINTS = 50;

const DATASET_CONFIG = [
  { key: 'memory', label: 'Memory', color: 'blue', hidden: false },
  {
    key: 'total_heap_size',
    label: 'Total Heap Size',
    color: 'red',
    hidden: true,
  },
  { key: 'heap_size', label: 'Heap Size', color: 'green', hidden: true },
  { key: 'stack_size', label: 'Stack Size', color: 'orange', hidden: true },
  { key: 'reductions', label: 'Reductions', color: 'purple', hidden: true },
  {
    key: 'message_queue_len',
    label: 'Message Queue Length',
    color: 'cyan',
    hidden: true,
  },
];

const ChartHook = {
  mounted() {
    this.initializeChart();
    this.setupEventHandlers();
  },

  setupEventHandlers() {
    this.handleEvent('update-chart', (data) => {
      this.updateChartData(data);
    });
  },

  initializeChart() {
    const style = getComputedStyle(document.documentElement);
    const primaryText = style.getPropertyValue('--primary-text').trim();
    const defaultBorder = style.getPropertyValue('--default-border').trim();

    this.chart = new Chart(this.el, {
      type: 'line',
      data: {
        labels: [],
        datasets: this.createDatasets(),
      },
      options: this.createChartOptions(primaryText, defaultBorder),
    });
  },

  createDatasets() {
    return DATASET_CONFIG.map(({ label, color, hidden }) => ({
      label,
      backgroundColor: color,
      borderColor: color,
      hidden,
      data: [],
    }));
  },

  createChartOptions(primaryText, defaultBorder) {
    return {
      responsive: true,
      maintainAspectRatio: false,
      animation: false,
      plugins: {
        legend: {
          labels: {
            color: primaryText,
          },
        },
      },
      scales: {
        x: {
          ticks: { color: primaryText },
          grid: { color: defaultBorder },
        },
        y: {
          ticks: { color: primaryText },
          grid: { color: defaultBorder },
          beginAtZero: true,
        },
      },
    };
  },

  updateChartData(data) {
    const timeString = this.formatTimestamp();
    this.chart.data.labels.push(timeString);

    DATASET_CONFIG.forEach(({ key }, index) => {
      const value = Number(data[key]);
      this.chart.data.datasets[index].data.push(value);
    });

    this.trimOldDataIfNeeded();
    this.chart.update('none');
  },

  formatTimestamp() {
    return new Date().toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: false,
    });
  },

  trimOldDataIfNeeded() {
    if (this.chart.data.labels.length > MAX_DATA_POINTS) {
      this.chart.data.labels.shift();
      this.chart.data.datasets.forEach((dataset) => dataset.data.shift());
    }
  },
};

export default ChartHook;
