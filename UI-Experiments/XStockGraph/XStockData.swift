import Foundation

// Fixed reference data traced from main-3.mp4, not a live market feed.
enum XStockRange: String, CaseIterable, Identifiable {
    case day = "1D", week = "1W", month = "1M", year = "1Y", all = "ALL"
    var id: Self { self }

    var accessibilityLabel: String {
        switch self {
        case .day: "One day"
        case .week: "One week"
        case .month: "One month"
        case .year: "One year"
        case .all: "All time"
        }
    }

    var comparisonPrice: Double {
        switch self {
        case .day: 198.05
        case .week: 181.48
        case .month: 183.02
        case .year, .all: 198.87 / 408.36
        }
    }

    var changeLabel: String {
        switch self {
        case .day: "↑ $0.82 (+0.42%)"
        case .week: "↑ $17.39 (+9.58%)"
        case .month: "↑ $15.85 (+8.66%)"
        case .year, .all: "↑ $198.38 (+40,736%)"
        }
    }

    func timestamp(at fraction: Double) -> String {
        let end = Date(timeIntervalSince1970: 1_744_920_000) // April 17, 2025, 8 PM UTC.
        let duration: TimeInterval = switch self {
        case .day: 10.5 * 3_600
        case .week: 7 * 86_400
        case .month: 30 * 86_400
        case .year: 365 * 86_400
        case .all: 26.25 * 365.25 * 86_400
        }
        let date = end.addingTimeInterval((min(max(fraction, 0), 1) - 1) * duration)
        var format = Date.FormatStyle.dateTime
            .month(.abbreviated).day()
            .hour(.defaultDigits(amPM: .abbreviated)).minute()
        format.locale = Locale(identifier: "en_US")
        format.timeZone = TimeZone(secondsFromGMT: 0)!
        return date.formatted(format)
    }
}

enum XStockChartStyle: String, CaseIterable, Identifiable {
    case line = "Line", thirtyMinutes = "30m", hour = "1h", fourHours = "4h"
    var id: Self { self }
}

struct XStockSample: Identifiable {
    let id: Int
    let fraction: Double
    let price: Double
}

struct XStockCandle: Identifiable {
    let id: Int
    let fraction: Double
    let open: Double
    let close: Double
    let high: Double
    let low: Double
}

struct XStockSeries {
    let range: XStockRange
    let samples: [XStockSample]
    let regularSamples: [XStockSample]
    let afterHoursSamples: [XStockSample]
    let regularLineSamples: [XStockSample]
    let afterHoursLineSamples: [XStockSample]
    let domain: ClosedRange<Double>

    init(range: XStockRange, trace: [Double]) {
        self.range = range
        let lastRegularIndex = switch range {
        case .day: 94
        case .week: 143
        default: trace.count - 1
        }
        let endPixel = trace[lastRegularIndex]
        // Fit the trace to the reference quote, preserving its exact geometry.
        let firstPrice = range == .year || range == .all ? 0.01 : range.comparisonPrice
        let startPixel = range == .year || range == .all ? 1755.0 : trace[0]
        let pricePerPixel = (198.87 - firstPrice) / (startPixel - endPixel)
        let lower = firstPrice + (startPixel - 1755) * pricePerPixel
        let upper = firstPrice + (startPixel - 1120) * pricePerPixel
        domain = lower...upper
        let fittedSamples = trace.enumerated().map { index, pixel in
            XStockSample(
                id: index,
                fraction: Double(index) / Double(trace.count - 1),
                price: firstPrice + (startPixel - pixel) * pricePerPixel
            )
        }
        samples = fittedSamples
        regularSamples = Array(samples.prefix(lastRegularIndex + 1))
        afterHoursSamples = lastRegularIndex < samples.count - 1 ? Array(samples.suffix(from: lastRegularIndex)) : []

        // Both rendered sessions keep every sample ID across range changes.
        // Unused vertices collapse onto the shared market-close point, so Charts
        // interpolates both paths together instead of removing/inserting marks.
        regularLineSamples = fittedSamples.enumerated().map { index, sample in
            let point = fittedSamples[min(index, lastRegularIndex)]
            return XStockSample(id: sample.id, fraction: point.fraction, price: point.price)
        }
        afterHoursLineSamples = fittedSamples.enumerated().map { index, sample in
            let point = fittedSamples[max(index, lastRegularIndex)]
            return XStockSample(id: sample.id, fraction: point.fraction, price: point.price)
        }
    }

    func sample(at fraction: Double) -> XStockSample {
        let clamped = min(max(fraction, 0), 1)
        return samples[Int((clamped * Double(samples.count - 1)).rounded())]
    }

    func candles(for style: XStockChartStyle) -> [XStockCandle] {
        if range == .week, style == .fourHours {
            return XStockReference.weeklyFourHourCandles(in: domain)
        }
        let count = switch style {
        case .line, .thirtyMinutes: 104
        case .hour: 52
        case .fourHours: 13
        }
        return (0..<count).map { index in
            let start = Double(index) / Double(count)
            let end = Double(index + 1) / Double(count)
            let points = samples.filter { $0.fraction >= start && $0.fraction <= end }
            let open = sample(at: start).price
            let close = sample(at: end).price
            let minBody = (domain.upperBound - domain.lowerBound) * 0.0018
            let bodyClose = abs(close - open) < minBody ? open + (index.isMultiple(of: 2) ? minBody : -minBody) : close
            return XStockCandle(
                id: index,
                fraction: (start + end) / 2,
                open: open,
                close: bodyClose,
                high: max(points.map(\.price).max() ?? open, open, bodyClose),
                low: min(points.map(\.price).min() ?? open, open, bodyClose)
            )
        }
    }
}

enum XStockReference {
    static func priceLabel(_ price: Double) -> String {
        price.formatted(.currency(code: "USD").locale(Locale(identifier: "en_US")))
    }

    private static let seriesByRange: [XStockRange: XStockSeries] = [
        .day: XStockSeries(range: .day, trace: dayTrace),
        .week: XStockSeries(range: .week, trace: weekTrace),
        .month: XStockSeries(range: .month, trace: monthTrace),
        .year: XStockSeries(range: .year, trace: yearTrace),
        .all: XStockSeries(range: .all, trace: allTrace)
    ]

    static func series(for range: XStockRange) -> XStockSeries {
        // All enum cases are defined above; this fallback also keeps previews total.
        seriesByRange[range] ?? XStockSeries(range: .day, trace: dayTrace)
    }

    static func weeklyFourHourCandles(in domain: ClosedRange<Double>) -> [XStockCandle] {
        // Open, close, high, low in the reference's chart coordinates.
        let trace: [(Double, Double, Double, Double)] = [
            (1290, 1240, 1230, 1294), (1239, 1241, 1228, 1254),
            (1240, 1123, 1086, 1255), (1126, 1119, 1091, 1135),
            (1119, 1125, 1109, 1131), (1128, 1131, 1093, 1142),
            (1128, 1109, 1098, 1135), (1109, 989, 980, 1110),
            (988, 930, 929, 990), (925, 934, 918, 950),
            (881, 934, 835, 937), (939, 888, 865, 940),
            (889, 881, 877, 891)
        ]
        func price(_ pixel: Double) -> Double {
            domain.lowerBound + (1755 - pixel * 1.35) / 635 * (domain.upperBound - domain.lowerBound)
        }
        return trace.enumerated().map { index, values in
            XStockCandle(id: index, fraction: (Double(index) + 0.5) / Double(trace.count), open: price(values.0), close: price(values.1), high: price(values.2), low: price(values.3))
        }
    }

    // Y positions in a common 1120...1755 plot frame. Stable sample identities
    // let Swift Charts morph each line into the next range instead of crossfading.
    private static let dayTrace: [Double] = [
        1462, 1482, 1552, 1500, 1484, 1431, 1381, 1363, 1364, 1346, 1332, 1308, 1288, 1282, 1240, 1249,
        1289, 1284, 1270, 1265, 1268, 1248, 1240, 1245, 1222, 1224, 1216, 1211, 1210, 1239, 1244, 1204,
        1160, 1152, 1203, 1223, 1248, 1231, 1231, 1251, 1252, 1243, 1256, 1307, 1406, 1434, 1482, 1522,
        1585, 1618, 1601, 1582, 1562, 1565, 1572, 1578, 1584, 1589, 1541, 1545, 1572, 1628, 1623, 1652,
        1694, 1703, 1683, 1642, 1620, 1650, 1624, 1615, 1579, 1561, 1558, 1563, 1556, 1558, 1564, 1563,
        1552, 1520, 1509, 1494, 1476, 1454, 1433, 1435, 1412, 1410, 1424, 1409, 1350, 1315, 1320, 1360,
        1397, 1421, 1405, 1407, 1412, 1419, 1431, 1456, 1454, 1457, 1458, 1440, 1424, 1423, 1422, 1419,
        1417, 1415, 1415, 1414, 1415, 1419, 1425, 1433, 1436, 1436, 1436, 1434, 1432, 1437, 1431, 1433,
        1433, 1432, 1433, 1428, 1411, 1414, 1417, 1408, 1398, 1406, 1406, 1401, 1401, 1401, 1397, 1404,
        1410, 1406, 1402, 1402, 1396, 1379, 1375, 1378, 1387, 1393, 1393
    ]

    private static let weekTrace: [Double] = [
        1717, 1714, 1697, 1684, 1677, 1666, 1657, 1655, 1654, 1655, 1656, 1655, 1654, 1659, 1664, 1657,
        1652, 1649, 1645, 1646, 1652, 1650, 1651, 1654, 1654, 1655, 1657, 1660, 1662, 1662, 1665, 1535,
        1520, 1498, 1482, 1470, 1475, 1496, 1500, 1499, 1498, 1503, 1502, 1493, 1494, 1494, 1489, 1477,
        1472, 1485, 1493, 1492, 1491, 1493, 1497, 1500, 1502, 1506, 1507, 1508, 1508, 1505, 1508, 1500,
        1482, 1473, 1485, 1498, 1504, 1501, 1501, 1503, 1506, 1508, 1510, 1512, 1507, 1498, 1494, 1487,
        1477, 1476, 1477, 1481, 1480, 1478, 1480, 1481, 1481, 1476, 1475, 1476, 1478, 1373, 1361, 1352,
        1346, 1343, 1332, 1318, 1304, 1303, 1308, 1304, 1302, 1302, 1305, 1303, 1292, 1266, 1254, 1249,
        1246, 1245, 1249, 1254, 1260, 1266, 1268, 1268, 1267, 1267, 1264, 1257, 1175, 1162, 1159, 1153,
        1144, 1145, 1148, 1153, 1172, 1220, 1232, 1237, 1251, 1237, 1228, 1218, 1200, 1182, 1168, 1174,
        1190, 1190, 1189, 1189, 1192, 1193, 1192, 1189, 1187, 1188, 1186
    ]

    private static let monthTrace: [Double] = [
        1417, 1431, 1419, 1424, 1434, 1433, 1429, 1422, 1425, 1426, 1427, 1452, 1463, 1462, 1464, 1495,
        1498, 1496, 1491, 1486, 1483, 1479, 1482, 1538, 1545, 1563, 1579, 1558, 1549, 1545, 1527, 1539,
        1528, 1529, 1542, 1537, 1532, 1548, 1547, 1545, 1544, 1525, 1516, 1519, 1463, 1476, 1485, 1489,
        1491, 1493, 1496, 1500, 1558, 1566, 1597, 1599, 1602, 1599, 1599, 1598, 1646, 1661, 1676, 1678,
        1679, 1683, 1671, 1678, 1693, 1703, 1717, 1718, 1721, 1717, 1634, 1587, 1586, 1568, 1563, 1567,
        1561, 1521, 1517, 1528, 1540, 1538, 1538, 1533, 1532, 1526, 1528, 1523, 1513, 1515, 1520, 1523,
        1515, 1514, 1522, 1512, 1508, 1512, 1518, 1523, 1546, 1540, 1540, 1499, 1494, 1443, 1416, 1441,
        1440, 1440, 1436, 1435, 1441, 1448, 1416, 1410, 1408, 1408, 1403, 1407, 1411, 1318, 1325, 1323,
        1321, 1321, 1321, 1326, 1322, 1316, 1327, 1329, 1318, 1314, 1315, 1312, 1238, 1226, 1220, 1211,
        1191, 1194, 1201, 1155, 1139, 1171, 1181, 1152, 1154, 1161, 1157
    ]

    private static let yearTrace: [Double] = [
        1712, 1725, 1707, 1663, 1668, 1672, 1646, 1646, 1635, 1629, 1604, 1541, 1537, 1536, 1540, 1552,
        1544, 1535, 1521, 1527, 1504, 1504, 1500, 1494, 1489, 1491, 1486, 1490, 1491, 1440, 1422, 1420,
        1422, 1414, 1417, 1394, 1384, 1385, 1349, 1345, 1349, 1349, 1337, 1325, 1311, 1325, 1309, 1308,
        1294, 1295, 1292, 1300, 1297, 1325, 1315, 1306, 1298, 1316, 1345, 1353, 1361, 1363, 1321, 1318,
        1318, 1334, 1312, 1289, 1315, 1311, 1287, 1264, 1265, 1275, 1250, 1266, 1264, 1300, 1290, 1292,
        1296, 1265, 1218, 1168, 1183, 1170, 1216, 1241, 1216, 1236, 1255, 1268, 1275, 1305, 1297, 1308,
        1316, 1304, 1294, 1287, 1278, 1286, 1326, 1320, 1329, 1295, 1268, 1257, 1253, 1262, 1266, 1261,
        1264, 1262, 1280, 1278, 1273, 1276, 1300, 1277, 1267, 1261, 1242, 1250, 1273, 1310, 1265, 1256,
        1259, 1287, 1278, 1260, 1249, 1235, 1236, 1302, 1294, 1286, 1297, 1275, 1271, 1288, 1282, 1297,
        1326, 1317, 1310, 1366, 1323, 1307, 1306, 1296, 1254, 1246, 1204
    ]

    private static let allTrace: [Double] = [
        1744, 1744, 1744, 1744, 1743, 1743, 1743, 1744, 1743, 1743, 1743, 1743, 1743, 1743, 1743, 1744,
        1743, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744,
        1744, 1744, 1744, 1744, 1744, 1743, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744,
        1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744,
        1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1744, 1743, 1743, 1743, 1743, 1742, 1742, 1741,
        1741, 1740, 1738, 1737, 1737, 1737, 1734, 1733, 1732, 1730, 1731, 1728, 1727, 1727, 1726, 1726,
        1725, 1730, 1735, 1734, 1732, 1733, 1733, 1733, 1731, 1730, 1727, 1724, 1724, 1719, 1715, 1708,
        1704, 1706, 1706, 1705, 1699, 1690, 1687, 1679, 1654, 1655, 1672, 1668, 1688, 1696, 1690, 1705,
        1699, 1698, 1678, 1665, 1630, 1612, 1609, 1612, 1604, 1560, 1486, 1484, 1363, 1371, 1378, 1324,
        1328, 1329, 1355, 1366, 1284, 1216, 1220, 1195, 1201, 1196, 1208
    ]
}
