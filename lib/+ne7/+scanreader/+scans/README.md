ScanImage scans. Each version handles things a little differently. Scan objects are 
usually instantiated by a call to scanreader.read_scan().

Hierarchy:
BaseScan
    ScanLegacy
    BaseScan5
        Scan5Point1
        Scan5Point2
            Scan2016b
            Scan2017a
            Scan2017b
    ScanMultiRoi