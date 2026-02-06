/**
 * Chart utilities for biomarker data processing
 * Similar to Rails helpers but for JavaScript chart functionality
*/

import * as dateFns from 'date-fns'

/**
* Groups biomarkers by their unit and value range to determine Y-axis assignments
* Each pair of unit and value range creates a new axis group.
* @param {Array<Object>} biomarkers - Array of biomarker objects containing unit and measures data
*   example:
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
* @returns {Array<Object>} Array of axis group objects containing:
*   - unit: The shared unit for the axis
*   - range: {min: number, max: number} The value range for the axis
*   - biomarkers: Array of biomarkers objects assigned to this axis
*   - axisPosition: The Y-axis position (left, right, far-right)
*/
function groupBiomarkersByAxis(biomarkers) {
 const axisGroups = new Map(); // Map is a JS structure that stores key-value pairs. Similar to a Ruby hash.

 biomarkers.forEach(biomarker => {
   const unit = biomarker.unit;
   const valueRange = this.calculateValueRange(biomarker.measures, biomarker.upperBand, biomarker.lowerBand); // this refers to the current instance of the Stimulus controller class. It's used to access the instance method calculateValueRange which is defined within the same controller class.
   const rangeBucket = this.getRangeBucket(valueRange.range, valueRange.min, valueRange.max)

   // Create axis key based on unit and range bucket
   // const axisKey = `${unit}_${rangeBucket.label}`;

   // Create axis key based on unit only
   const axisKey = `${unit}`

   if(!axisGroups.has(axisKey)) {
     axisGroups.set(axisKey, {
       unit: unit,
       rangeBucket: rangeBucket,
       range: valueRange,
       biomarkers: [],
       axisPosition: this.getNextAxisPosition(axisGroups.size) // At each iteration, axisGroups.size is incremented by 1 if a new axisKey is found.
     });
   }

   // Update the group's actual range to accommodate all biomarkers in the group
   const group = axisGroups.get(axisKey);
   group.range.min = Math.min(group.range.min, valueRange.min);
   group.range.max = Math.max(group.range.max, valueRange.max);

   // Add biomarker object to the object group
   group.biomarkers.push(biomarker);
 });

 return Array.from(axisGroups.values());

}

// Calculate the value range for a biomarker
function calculateValueRange(measures, upperBand, lowerBand) {
  const values = Object.values(measures).filter(v => v!== null)
  const upperBandValues = Object.values(upperBand).filter(v => v!== null)
  const lowerBandValues = Object.values(lowerBand).filter(v => v!== null)
  const biomarkerMinValue = Math.min(...lowerBandValues, Math.min(...values)) // Spread operator is used to expand the array into individual elements.
  const biomarkerMaxValue = Math.max(Math.max(...upperBandValues), Math.max(...values))

  return {
    min: biomarkerMinValue,
    max: biomarkerMaxValue,
    range: biomarkerMaxValue - biomarkerMinValue
  };
}

/**
 * Determines the Y-axis position for a biomarker group based on its index
 * @param {number} axisIndex - The index of the axis group (0-based)
 * @returns {string} The position of the Y-axis ('left', 'right')
 * @description
 * - First biomarker group (index 0) gets the left Y-axis
 * - Second biomarker group (index 1) gets the right Y-axis
 * - Third biomarker group (index 2) gets the right Y-axis with different styling
 * - Any additional groups (index > 2) default to right Y-axis
 */
function getNextAxisPosition(axisIndex) {
  const positions = ['left', 'right', 'right'];
  return positions[axisIndex] || 'right';
}


/**
 * Prepares band data with placeholder values and fill missing dates with null values.
 * @param {Object} bandData - Object containing the band data
 * @param {Array} unifiedLabels - Complete array of all label
 * @returns {Array} Array of band data values aligned with unified labels
 * @example
 * prepareBandData({ "2023-01": 12.5, "2023-02": 13.1 }, ['2023-01', '2023-02'])
 * Returns: [12.5, 13.1]
 * prepareBandData({ "2023-01": 12.5, "2023-02": 13.1 }, ['2023-01', '2023-02', '2023-03'])
 * Returns: [12.5, 13.1, null]
 * prepareBandData({ "2023-01": 12.5, "2023-02": 13.1 }, ['2023-01', '2023-02', '2023-03', '2023-04'])
 * Returns: [12.5, 13.1, null, null]
 */

function prepareBandData(bandData, unifiedLabels) {
  const values = Object.values(bandData); // returns an array of values from the bandData object
  const preparedData = [];

  // For each unified label, get the value or use a fallback value (if the biomarker data is missing for that date)
  unifiedLabels.forEach(label => {
    if (bandData && bandData[label] !== undefined) {
      preparedData.push(bandData[label]);
    } else {
      const fallbackValue = preparedData.length > 0 ? preparedData[preparedData.length - 1] : bandData[Object.keys(bandData)[0]];
      preparedData.push(fallbackValue);
    }
  });

  // Add palceholder values for chart centering
  if (preparedData.length > 0) {
    preparedData.unshift(preparedData[0]);
    preparedData.push(preparedData[preparedData.length - 1]);
  } else {
    preparedData.unshift(null);
    preparedData.push(null);
  }

  return preparedData;
}


/**
 * Prepares measures data with placeholder values
 * @param {Object} measuresData - Measures data object
 * @param {Array} unifiedLabels - Complete array of all labels
 * @returns {Array} Prepared measures data array
 */
function prepareMeasuresData(measuresData, unifiedLabels) {
  const preparedData = [];

  // For each unified label, get the value or use null
  unifiedLabels.forEach(label => {
    if (measuresData && measuresData[label] !== undefined) {
      preparedData.push(measuresData[label]);
    } else {
      preparedData.push(null); // Missing data points are null
    }
  });

  // Add placeholder null values
  preparedData.unshift(null);
  preparedData.push(null);

  return preparedData;
}

/**
 * Gets color for biomarker series
 * @param {number} datasetOrderCounter - Index of biomarker in the datasets array.
 * @returns {string} Color hex code
 */
// To Do: When we select Body Composition, the colors repear//
function getBiomarkerColor(datasetOrderCounter) {
  const colors = [
    '#B9D7FA', // Primary blue
    '#FFB3BA', // Secondary pink
    '#BAF991', // Tertiary green
    '#C4A484', // Quaternary yellow
    '#FFDF99'  // Quinary orange
  ];
  return colors[datasetOrderCounter % colors.length];
}


/**
 * Gets point color based on range status (only for primary biomarker)
 * @param {Object} context - Chart.js context object
 * @param {Object} biomarker - Biomarker object
 * @param {Array} preparedUpperBand - Already prepared upper band array
 * @param {Array} preparedLowerBand - Already prepared lower band array
 * @param {boolean} isPrimary - Whether the biomarker is the primary biomarker
 * @returns {string} Color hex code
 */
function getPointColor(context, preparedUpperBand, preparedLowerBand, datasetOrderCounter, isPrimary) {
  if (!isPrimary) {
    return ChartUtils.getBiomarkerColor(datasetOrderCounter);
  }

  // Primary biomarker range-based colors
  // context.dataset.data is an array containing all the data points for this dataset
  // context.dataIndex is the index of the current data point being rendered
  // So value gets the specific data point value at the current index
  // value is a number representing the biomarker measurement value at this data point
  const value = context.dataset.data[context.dataIndex];

  // upperBandY is a number representing the upper bound of the normal range at this data point
  const upperBandY = preparedUpperBand[context.dataIndex];

  // lowerBandY is a number representing the lower bound of the normal range at this data point
  const lowerBandY = preparedLowerBand[context.dataIndex];

  // Getting colors from css root
  const rootStyles = getComputedStyle(document.documentElement);
  const yellow = rootStyles.getPropertyValue('--yellow').trim();
  const green = rootStyles.getPropertyValue('--green').trim();
  const blue = rootStyles.getPropertyValue('--blue').trim();

  if (upperBandY == null) {
    return blue;
  } else {
    if (value > upperBandY) {
      return yellow;
    } else if (value < lowerBandY) {
      return yellow;
    } else {
      return green;
    }
  }

}

/**
 * Adds placeholder labels for chart centering
 * @param {Array} labels - Labels array to add placeholders to
 * @returns {Array} New array with placeholder labels added
 */
function addPlaceholderLabels(labels) {
  //return labels;
  //console.log('Label[0]', labels[0]);
  //console.log('Adding Label', dateFns.addDays(labels[0],30));
  const start = labels[0];
  const end = labels[labels.length - 1];

  if (end === start) {
    const shifter = 30;
    return [dateFns.startOfMonth(dateFns.addDays(start, -shifter)), ...labels, dateFns.endOfMonth(dateFns.addDays(end,shifter))];
  } else {
    const shifter = dateFns.differenceInDays(end, start) / 17;
    //console.log('Shifter', shifter);
    return [dateFns.startOfMonth(dateFns.addDays(start, -shifter)), ...labels, dateFns.endOfMonth(dateFns.addDays(end,shifter))];
  }

}

/**
 * Transforms date strings from "YYYY-MM-DD" format to "DD/MM/YYYY" format.
 * If the label is empty or a placeholder, it is returned unchanged.
 * @param {Array<String>} labels - Array of date strings in "YYYY-MM-DD" format
 * @returns {Array<String>} Array of date strings in "DD/MM/YYYY" format
 * @example
 * transformLabelsToDdMmYyyy(["2023-01-15", "2024-12-05"])
 * // Returns: ["15/01/2023", "05/12/2024"]
 */
function transformLabelsToDdMmYyyy(labels) {
  return labels.map(label => {
    // Handle empty strings (placeholders)
    if (!label || label.trim() === '') {
      return label;
    }


    const [year, month, day] = label.split('-');
    return `${day}/${month}/${year}`;
  });
}



/**
 * Determines the range bucket for a given biomarker series
 * @param {number} range - The value range (max-min)
 * @returns {Object} Bucket information with min, max and label
 */
function getRangeBucket(range, minValue, maxValue) {
  if (range<=1) {
    return {min: minValue, max: maxValue, label: '0-1'};
  } else if (range <= 5) {
    return { min: minValue, max: maxValue, label: '1-5' };
  } else if (range <= 25) {
    return { min: minValue, maxValue: maxValue, label: '5-25' };
  } else if (range <= 50) {
    return { min: minValue, maxValue: maxValue, label: '25-50' };
  } else if (range <= 100) {
    return { min: minValue, maxValue: maxValue, label: '50-100' };
  } else if (range <= 200) {
    return { min: minValue, maxValue: maxValue, label: '100-200' };
  } else {
    // Formula: Ranges growth by 200 units. How many times does 200 fit into the range?
    // Math.ceil(range / rangeIncrement) * rangeIncrement
    const rangeIncrement = 200;
    const rangeIncrementCount = Math.ceil(range / rangeIncrement); // Ex.: Range 601 -> 4 times 200 units (after rounding up). // Range 599 -> 3 times 200 units (after rounding up).
    const rangeUpperBound = rangeIncrementCount * rangeIncrement;
    const rangeLowerBound = rangeUpperBound - rangeIncrement;

    return { min: minValue, max: maxValue, label: `${rangeLowerBound}-${rangeUpperBound}` };
  }
}

/**
 * Merges labels from all biomarkers into a unified, sorted timeline
 * @paramm {Array<Object>} biomarkers - Array of biomarker objects containing measures data -> See Static variable biomarkerData defintion.
 * @returns {Array<String>} Unified, sorted array of all unique labels
 */
function mergeLabelsFromBiomarkers(biomarkers) {
  const allLabels = new Set(); // Labels are unique, so we use a Set.

  biomarkers.forEach(biomarkers => {
    Object.keys(biomarkers.measures).forEach(label => {
      allLabels.add(label);
    });
  });

  let sortedLabels = Array.from(allLabels).sort();

  return sortedLabels;
}

/**
 * Parse date string from "DD/MM/YYYY" format and create a Date object
 * @param {String} dateString - Date string in "DD/MM/YYYY" format
 * @returns {Date} The parsed date object
 */

function parseDate(dateString) {
  const [day, month, year] = dateString.split('/');
  return new Date(`${year}-${month}-${day}`);
}

/**
 * Create a timeline array with Date objects
 * @param {Array<String>} labels - Array of date strings in "dd/mm/yyyy" format
 * @returns {Array<Date>} Array of Date objects
 * @example
 * createTimeline(["01/01/2023", "02/05/2023", "03/08/2023"])
 * // Returns: [new Date("2023-01-01"), new Date("2023-05-02"), new Date("2023-08-03")]
 */

function createTimeline(labels) {
  // console.log('labels', labels);
  return labels.map(label => {
    return parseDate(label);
  });
}



/**
* Helper function to calculate step size
* Step size divides the range into 5 equal parts.
*/
function calculateStepSize(min, max) {
  const range = max - min;
  if (range <= 1) return 0.2;
  if (range <= 3) return 0.6;
  if (range <= 5) return 1;
  if (range <= 10) return 2;
  if (range <= 20) return 4;
  if (range <= 40) return 8;
  if (range <= 50) return 10;          // Small range
  if (range <= 100) return 20;        // Medium range
  return Math.ceil(range / 5);       // Larger range, divide range by 5
}

/**
 * Helper method to create test data
 * Call this from browser console: window.testBiomarkers = controller.createTestData()
 */
function createTestData() {
  return [
    {
      name: "Hemoglobin",
      unit: "g/dL",
      measures: { "2023-01-03": 12.5, "2023-02-01": 13.1, "2023-03-15": 12.8, "2023-04-20": 14.2 },
      upperBand: { "2023-01-03": 15.5, "2023-02-01": 15.5, "2023-03-15": 15.5, "2023-04-20": 15.5 },
      lowerBand: { "2023-01-03": 12.0, "2023-02-01": 12.0, "2023-03-15": 12.0, "2023-04-20": 12.0 }
    },
    {
      name: "Glucose",
      unit: "mg/dL",
      measures: { "2023-01-15": 95, "2023-03-15": 102, "2023-04-20": 98, "2023-05-10": 105 },
      upperBand: { "2023-01-15": 100, "2023-03-15": 100, "2023-04-20": 100, "2023-05-10": 100 },
      lowerBand: { "2023-01-15": 70, "2023-03-15": 70, "2023-04-20": 70, "2023-05-10": 70 }
    },
    {
      name: "Cholesterol",
      unit: "mg/dL",
      measures: { "2023-02-20": 200, "2023-03-20": 205, "2023-06-20": 195, "2023-07-15": 210 },
      upperBand: { "2023-02-20": 210, "2023-03-20": 210, "2023-06-20": 210, "2023-07-15": 210 },
      lowerBand: { "2023-02-20": 150, "2023-03-20": 150, "2023-06-20": 150, "2023-07-15": 150 }
    }
  ];
}


// Export as a namespaced object
export const ChartUtils = {
  addPlaceholderLabels,
  createTestData,
  groupBiomarkersByAxis,
  calculateValueRange,
  getRangeBucket,
  getNextAxisPosition,
  mergeLabelsFromBiomarkers,
  prepareBandData,
  prepareMeasuresData,
  calculateStepSize,
  getBiomarkerColor,
  getPointColor,
  transformLabelsToDdMmYyyy,
  parseDate,
  createTimeline,
};
