import { Controller } from "@hotwired/stimulus";
import { Chart, registerables } from "chart.js";
import { ChartUtils } from "helpers/chart_utils"; // instead of "../helpers/chart_utils.js";
import { ChartConfig } from "helpers/chart_config"; // instead of "../helpers/chart_config.js";
import 'chartjs-adapter-date-fns';
import * as dateFns from 'date-fns';

// ptBRLocale is a configuration object that tells date-fns how to format dates in Portuguese (Brazil), and passing it to the adapter makes your chart display dates in Portuguese.
import { ptBR as ptBRLocale } from 'date-fns/locale/pt-BR';

Chart.register(...registerables);

// Make modules availbale foe debug purposes
window.Chart = Chart;
window.ChartUtils = ChartUtils;
window.dateFns = dateFns;

/**
* Chart controller for rendering biomarker measurement charts
* Connects tthe controller to the HTML element that has the data-controller="chart" attribute.
* @example
* // HTML usage:
* <div data-controller="chart">
*   <canvas data-chart-target="measures"></canvas>
* </div>
*
* // Static values example:
*   biomarkerData: Array
*   [
*     {
*       name: "Hemoglobin",
*       unit: "g/dL",
*       measures: { "2023-01": 12.5, "2023-02": 13.1, ... },
*       upperBand: { "2023-01": 15.5, "2023-02": 15.5, ... },
*       lowerBand: { "2023-01": 12.0, "2023-02": 12.0, ... }
*     },
*     {
*      name: "Glucose",
*       unit: "mg/dL",
*       measures: { "2023-01": 95, "2023-02": 102, ... },
*       upperBand: { "2023-01": 100, "2023-02": 100, ... },
*       lowerBand: { "2023-01": 70, "2023-02": 70, ... }
*     }
*   ]
*/
export default class extends Controller {
  static targets = ["measures"];
  static values = {

    biomarkersData: {type: Array, default: []}, // Handle Missing Data Gracefully
    maxAxes: {type: Number, default: 10} // {type: Number, default: 3} is plain object. Number is a JS constructor.
  };

  chart = null;

  /**
  * Test method to dynamically update biomarkers data and reconnect
  * Call this from browser console to test multi-biomarker functionality.
  * @param {Array} testBiomarkers - Array of biomarker objects for testing.
  */
  testChart(testBiomarkers) {

  // Destroy existing chart if it exists
  if (this.chart) {
    this.chart.destroy();
    this.chart = null;
  }

  // Update the data attribute
  this.biomarkersDataValue = testBiomarkers; // updates the biomarkerData static value. In Stimulus, appending Value to a static value name (biomarkersDataValue) is the setter syntax for updating that value.

  // Reconnect the controller
  this.connect();
  }

/**
* Creates an empty chart when no data is available
* @param {CanvasRenderingContext2D} ctx - Canvas context
* @returns {void}
*/
createEmptyChart(ctx) {
  const data = {
    labels: ['No Data'],
    datasets: [{
      label: 'No data available',
      data: [0],
      borderColor: '#e0e0e0',
      backgroundColor: '#f5f5f5',
      pointRadius: 0
    }]
  };
  this.chart = new Chart(ctx, { type: 'line', data: data });
}

  connect() {
    // getContext("2d") returns a 2D rendering context for drawing on the canvas
    // This context provides methods and properties for drawing shapes, text, images etc
    // "2d" specifies we want a 2D context rather than WebGL or other contexts
    const ctx = this.measuresTarget.getContext("2d");
    const biomarkersData = this.biomarkersDataValue;
    // console.dir(biomarkersData, { depth: null });

    // Handle backward compatibility
    if (!biomarkersData || biomarkersData.length === 0) {
      this.createEmptyChart(ctx);
      return;
    }

    // Group biomarkers by axis and limit  AxisGroups to displayed to maxAxes
    const axisGroups = ChartUtils.groupBiomarkersByAxis(biomarkersData);
    //console.log('axisGroups', axisGroups);

    const limitedAxisGroups = axisGroups.slice(0, this.maxAxesValue);
    //console.log('limitedAxisGroups', limitedAxisGroups);

    // Merge all labels from all biomarkers into unified timeline
    const unifiedLabels = ChartUtils.mergeLabelsFromBiomarkers(biomarkersData);
    //console.log('unifiedLabels', unifiedLabels);

    const unifiedLabelsFormattedToDdMmYyyy = ChartUtils.transformLabelsToDdMmYyyy(unifiedLabels);
    // console.log('unifiedLabelsFormattedToDdMmYyyy', unifiedLabelsFormattedToDdMmYyyy);

    const timeline = ChartUtils.createTimeline(unifiedLabelsFormattedToDdMmYyyy);
    // console.log('timeline', timeline);

    // Create labels array with placeholders for chart centering
    const labelsWithPlaceholders = ChartUtils.addPlaceholderLabels(timeline);
    // console.log('labelsWithPlaceholders', labelsWithPlaceholders);

    // Create Y-axis configuration
    const yAxisConfig = ChartConfig.createYAxisConfig(limitedAxisGroups);
    // console.log('yAxisConfig', yAxisConfig);

    // Create datasets
    const datasets = ChartConfig.createMultiBiomarkerDatasets(limitedAxisGroups, unifiedLabels);
    // console.log('datasets', datasets);

    // Set Chart.js defaults
    Chart.defaults.font = {
      family: '"Work Sans", "Helvetica", "sans-serif"',
      size: 14,
      weight: 'normal',
      lineHeight: 1.2,
    };

    // console.log("labelsWithPlaceholders:", labelsWithPlaceholders);
    // console.log("timeline:", timeline);


    // Create chart data
    const data = {
      labels: labelsWithPlaceholders,
      datasets: datasets,
    };

    // Create chart options
    const options = {
      responsive: true,
      devicePixelRatio: window.devicePixelRatio || 1,
      maintainAspectRatio: false,
      scales: {
        x: {
          grid: {},
          type: 'time',
          bounds: 'ticks', // Ensures first and last ticks align with chart edges
          //bounds: 'data', // Ensures first and last ticks align with chart edges
          time: {
            unit: 'month',
            tooltipFormat: 'PP', // Portuguese format: "14 Fev 2025"
            displayFormats: {
              month: 'MMM yyyy', // Portuguese format: "Fev 2025"
              day: 'dd MMM yyyy' // Portuguese format: "14 Fev 2025"
            }
          },
          adapters: {
            date: {
              zone: 'utc', // Display time in UTC timezone. By default, Chart.js displays time in the local timezone.
              locale: ptBRLocale // Use Portuguese (Brazil) locale for date formatting (imported from date-fns ESM)
            }
          },
          ticks: {
            padding: window.innerWidth < 576 ? 5 : 15,
            autoSkip: true,
            maxRotation: window.innerWidth < 576 ? 0 : 0,
            minRotation: window.innerWidth < 576 ? 0 : 0,
            font: {
              size: window.innerWidth < 576 ? 10 : 12,
            },
            maxTicksLimit: window.innerWidth < 576 ? 4 : 8
          }
        },
        ...yAxisConfig
      },
      plugins: {
        tooltip: {
          // filter is a Chart.js tooltip plugin property that lets you control which data points/tooltips are shown.
          // The filter property for Chart.js tooltips uses a function (tooltipItem) => ... to determine which tooltip items to show; returning false (e.g., if skipTooltip is true) excludes that item from the tooltip
          // tooltipItem is an object representing each item that could be shown in the tooltip (including info about the dataset and data point).
          filter: (tooltipItem) => !tooltipItem.dataset.skipTooltip,
          callbacks: {
            label: (tooltipItem) => {
              const dataset = tooltipItem.dataset;
              const value = tooltipItem.raw;

              // // Handle null/undefined values
              // if (value === null || value === undefined) {
              //   return `${dataset.label}: N/A`;
              // }

              // Format value (show 1 decimal for small values, round for larger values)
              const formattedValue = value < 100 ? value.toFixed(1) : Math.round(value);

              // Get unit from dataset, fallback to empty string if not available
              const unit = dataset.unit || '';

              // Return formatted label with unit
              return `${formattedValue} ${unit}`.trim();
            }
          }
        },
        legend: {

          display: true,
          position: 'top',
          labels: {
            usePointStyle: true,
            font: {
              size: window.innerWidth < 576 ? 10 : 12,
            },
            filter: (item, data) => {
              const dataset = data.datasets[item.datasetIndex];
              return !dataset?.skipLegend;
            },
            // Synchronize legend labels with dataset colors
            // generateLabels is a method (function property) of the legend.labels configuration object in Chart.js. It defines how legend label items are generated.
            generateLabels: (chart) => {

              // Chart.defaults.plugins.legend.labels is a configuration object for the legend labels in Chart.js;
              // This configuration object contains properties and methods, most notably generateLabels, which is a function that returns an array of legend label objects for the chart.
              const labels = Chart.defaults.plugins.legend.labels.generateLabels(chart);
              labels.forEach((label) => {
                const dataset = chart.data.datasets[label.datasetIndex];
                if (dataset?.borderColor) {
                  label.fillStyle = dataset.borderColor;
                  label.strokeStyle = dataset.borderColor;
                }
              });
              return labels;
            }
          }
        }
      }
    };

    // Initialize the chart
    this.chart = new Chart(ctx, {
      type: 'line',
      data: data,
      options: options,
    });
  }
}
