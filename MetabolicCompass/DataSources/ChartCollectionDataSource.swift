//
//  ChartCollectionDataSource.swift
//  ChartsMC
//
//  Created by Artem Usachov on 6/1/16.  
//  Copyright © 2016 SROST. All rights reserved.
//

import Foundation
import UIKit
import Charts
import HealthKit
import MetabolicCompassKit


class ChartCollectionDataSource: NSObject, UICollectionViewDataSource {
 
    internal var collectionData: [ChartData] = []
    internal var model: BarChartModel?
    internal var data: [HKSampleType] = PreviewManager.chartsSampleTypes
    private let appearanceProvider = DashboardMetricsAppearanceProvider()
    private let barChartCellIdentifier = "BarChartCollectionCell"
    private let lineChartCellIdentifier = "LineChartCollectionCell"
    private let scatterChartCellIdentifier = "ScatterChartCollectionCell"

    func updateData () {
        data = PreviewManager.chartsSampleTypes
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    @available(iOS 6.0, *)

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: BaseChartCollectionCell
        let type = data[indexPath.row]
        let typeToShow = type.identifier == HKCorrelationTypeIdentifier.bloodPressure.rawValue ? HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue : type.identifier
        let chartType: ChartType = (model?.chartTypeForQuantityTypeIdentifier(qType: typeToShow))!
        let key = typeToShow + "\((model?.rangeType.rawValue)!)"
        let chartData = model?.typesChartData[key]
        switch chartType {
        case .BarChart:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: barChartCellIdentifier, for: indexPath as IndexPath) as! BarChartCollectionCell
        case .LineChart:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: lineChartCellIdentifier, for: indexPath as IndexPath) as! LineChartCollectionCell
        case .ScatterChart:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: scatterChartCellIdentifier, for: indexPath as IndexPath) as! ScatterChartCollectionCell
        }
        cell.chartView.xAxis.valueFormatter = nil
        if let yMax = chartData?.yMax, let yMin = chartData?.yMin, yMax > 0 || yMin > 0 {
            cell.updateLeftAxisWith(minValue: chartData?.yMin, maxValue: chartData?.yMax)
        }
        cell.chartView.data = chartData

        guard let range = model?.rangeType else {return cell}
        guard let xValues = model?.titlesFor(range: range) else {return cell}
        let chartFormatter = BarChartFormatter(labels: xValues)
        let xAxis = XAxis()
        xAxis.valueFormatter = chartFormatter
        cell.chartView.xAxis.valueFormatter = xAxis.valueFormatter
        cell.chartView.xAxis.axisMinimum = 0.0
        if xValues.count > 0 {
            cell.chartView.xAxis.axisMaximum = Double (xValues.count - 1)
        }
        cell.chartView.xAxis.valueFormatter = xAxis.valueFormatter
        cell.chartTitleLabel.text = appearanceProvider.stringForSampleType(typeToShow == HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue ? HKCorrelationTypeIdentifier.bloodPressure.rawValue : typeToShow)
        cell.chartView.setNeedsDisplay()
        return cell
    }
}

private class BarChartFormatter: NSObject, IAxisValueFormatter {

    var labels: [String] = []
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let index = axis?.entries.index(of: value)
        return labels[Int((axis?.entries[index!])!)]
    }
    init(labels: [String]) {
        super.init()
        self.labels = labels
    }
}
