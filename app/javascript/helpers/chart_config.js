/**
 * Chart configuration utilities for Chart.js
*/

import { ChartUtils } from "helpers/chart_utils"; // instead of './chart_utils';

/**
 * Creates Y-axis configuration for Chart.js based on axis groups
 * @param {Array<Object>} axisGroups - Array of axis group objects
 * @returns {Object} Chart.js Y-axis scales configuration
 * @example
 * const axisGroups = [
 *   {
 *     unit: "g/dL",
 *     range: {min: 10, max: 100},
 *     biomarkers: [{
 *                  name: "Hemoglobin",
 *                  unit: "g/dL",
 *                  measures: { "2023-01": 12.5, "2023-02": 13.1, ... },
 *                  upperBand: { "2023-01": 15.5, "2023-02": 15.5, ... },
 *                  lowerBand: { "2023-01": 12.0, "2023-02": 12.0, ... }
 *                  }],
 *     axisPosition: 'left'
 *   },
 *   {
 *     unit: "mg/dL",
 *     range: {min: 70, max: 150},
 *     biomarkers: [...],
 *     axisPosition: 'right'
 *   }
 * ]
 */

 function createYAxisConfig(axisGroups) {
  const scales = {};

  console.log('axisGroups', axisGroups);
  axisGroups.forEach((group, index) => {
    const axisId = index === 0 ? 'y' : `y${index}`;
    const position = group.axisPosition;

    scales[axisId] = {
      type: 'linear',
      display: index <= 0 ? true : false, // Only display Axis for group index 0 (left axis)
      position: position,
      grid: {display: false},
      beginAtZero: index === 0 ? true : false,
      max: Math.round(ChartUtils.calculateStepSize(0, group.range.max) * 6 * 100) / 100,
      title: {
        display: true,
        text: group.unit,
        //padding: { top: 10, bottom: 10 },
        font: { size: window.innerWidth < 576 ? 8 : 12 }
      },
      ticks: { // Configures how the axis tick marks (small lines on the axis) and labels are displayed
        padding: window.innerWidth < 576 ? 5 : 5, // Adjust padding based on screen width / padding around ticks
        display: true,
        font: { size: window.innerWidth < 576 ? 10 : 12 },
        stepSize: ChartUtils.calculateStepSize(0, group.range.max),
        callback: function(value) {
          if (value < 10) {
            return value.toFixed(1);
          }
          return Math.round(value);
        }
      },
      border: {display: false}
    };
  });

  return scales;
}


/**
 * Creates datasets for multiple biomarkers.
 * Only the first biomarker (primary biomarker) gets upper and lower bands, while all other biomarkers only get their measures data.
 *
 * @param {Array<Object>} axisGroups - Array of axis group objects
 * @param {Array} labels - X-axis labels as Strings
 * @returns {Array} Chart.js datasets array
 * @example
 *   createMultiBiomarkerDatasets([{
 *     unit: 'g/dL',
 *     range: {min: 0, max: 20},
 *     biomarkers: [{
 *       name: 'Hemoglobin',
 *       measures: {'2023-01': 12.5, '2023-02': 13.1},
 *       lowerBand: {'2023-01': 12.0, '2023-02': 12.0},
 *       upperBand: {'2023-01': 15.5, '2023-02': 15.5}
 *     }]
 *   }], ['2023-01', '2023-02'])
 *   Returns:
 *   [{
 *      label: 'Hemoglobin - Lower band',
 *      data: [12.0, 12.0],
 *      yAxisID: 'y',
 *      ...
 *    }, {
 *      label: 'Hemoglobin - Upper band',
 *      data: [15.5, 15.5],
 *      yAxisID: 'y',
 *      ...
 *    }, {
 *      label: 'Hemoglobin',
 *      data: [12.5, 13.1],
 *      yAxisID: 'y',
 *      ...
 *    }]
 *    // other biomarkers follows...
 */
function createMultiBiomarkerDatasets(axisGroups, labels) {
  const datasets = [];
  let datasetOrderCounter = 0;

  axisGroups.forEach((group, groupIndex)=>{
    const axisId = groupIndex === 0 ? 'y' : `y${groupIndex}`;
    group.biomarkers.forEach((biomarker, biomarkerIndex) => {
      // Only add bands for the first biomarker (primary biomarker)
      if (groupIndex === 0 && biomarkerIndex === 0) {
        // Add lower band dataset for primary biomarker only
        datasets.push({
          label: `${biomarker.name} - Lower band`,
          unit: group.unit,
          skipLegend: true,
          data: ChartUtils.prepareBandData(biomarker.lowerBand, labels),
          fill: false,
          borderColor: 'rgba(155, 238, 155, 0.3)',
          tension: 0.1,
          pointRadius: 0,
          yAxisID: axisId,
          skipTooltip: true,
          order: null,
        });

        // Add upper band dataset for primary biomarker only
        datasets.push({
          label: `${biomarker.name} - Upper band`,
          unit: group.unit,
          skipLegend: true,
          data: ChartUtils.prepareBandData(biomarker.upperBand, labels),
          backgroundColor: 'rgba(155, 238, 155, 0.1)',
          fill: '-1',
          borderColor: 'rgba(155, 238, 155, 0.3)',
          tension: 0.1,
          pointRadius: 0,
          yAxisID: axisId,
          skipTooltip: true,
          order: null,
        });
      }

      // Prepare band data for point coloring (only needed for primary biomarker)
      let preparedUpperBand, preparedLowerBand;
      if (groupIndex === 0 && biomarkerIndex === 0) {
        preparedUpperBand = ChartUtils.prepareBandData(biomarker.upperBand, labels);
        preparedLowerBand = ChartUtils.prepareBandData(biomarker.lowerBand, labels);
      }

      // Bigger point radius for primary biomarker
      // Different point radius for mobile (max-width: 575px)
      let pointRadius;
      if (groupIndex === 0 && biomarkerIndex === 0) {
        pointRadius = window.matchMedia('(max-width: 575px)').matches ? 3 : 4;
      } else {
        pointRadius = window.matchMedia('(max-width: 575px)').matches ? 2 : 3;
      }
      // console.log('pointRadius', pointRadius);


      // Capture the current counter value to ensure proper closure behavior
      const currentCounter = datasetOrderCounter;
      const isPrimaryBiomarker = groupIndex === 0 && biomarkerIndex === 0;

      // Add biomarker measures dataset for all biomarkers
      datasets.push({
        label: biomarker.name,
        unit: group.unit,
        data: ChartUtils.prepareMeasuresData(biomarker.measures, labels),
        fill: false,
        borderColor: ChartUtils.getBiomarkerColor(currentCounter), // The color of the line connecting the data points
        borderWidth: 3, // The width of the line connecting the data points
        tension: 0.1,
        pointRadius: pointRadius,
        pointBorderWidth: 2,
        pointBorderColor: (context) => ChartUtils.getPointColor(context, preparedUpperBand, preparedLowerBand, currentCounter, isPrimaryBiomarker), // The outline color of each data point
        pointBackgroundColor: (context) => ChartUtils.getPointColor(context, preparedUpperBand, preparedLowerBand, currentCounter, isPrimaryBiomarker), // The fill color of each data point
        spanGaps: true, // This connects points across null values
        yAxisID: axisId,
        skipTooltip: false,
        order: currentCounter
      });

      datasetOrderCounter++;
    });
  });

  return datasets;
}

// Export as a namespaced object
export const ChartConfig = {
  createYAxisConfig,
  createMultiBiomarkerDatasets
};
