import 'dart:io';

void main() {
  final lcovFile = File('coverage/lcov.info');
  if (!lcovFile.existsSync()) {
    print('Error: coverage/lcov.info not found. Please run "flutter test --coverage" first.');
    exit(1);
  }

  final lines = lcovFile.readAsLinesSync();
  final files = <FileCoverage>[];

  String? currentFile;
  int totalLines = 0;
  int coveredLines = 0;
  final lineCoverage = <int, int>{}; 

  for (var line in lines) {
    line = line.trim();
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3);
      totalLines = 0;
      coveredLines = 0;
      lineCoverage.clear();
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      if (parts.length == 2) {
        final lineNum = int.tryParse(parts[0]) ?? 0;
        final hits = int.tryParse(parts[1]) ?? 0;
        lineCoverage[lineNum] = hits;
      }
    } else if (line.startsWith('LF:')) {
      totalLines = int.tryParse(line.substring(3)) ?? 0;
    } else if (line.startsWith('LH:')) {
      coveredLines = int.tryParse(line.substring(3)) ?? 0;
    } else if (line == 'end_of_record') {
      if (currentFile != null) {
        files.add(FileCoverage(
          filePath: currentFile,
          totalLines: totalLines,
          coveredLines: coveredLines,
          lineHits: Map.from(lineCoverage),
        ));
      }
      currentFile = null;
    }
  }

  // Sort files by path name
  files.sort((a, b) => a.filePath.compareTo(b.filePath));

  // Calculate overall stats
  final grandTotalLines = files.fold<int>(0, (sum, f) => sum + f.totalLines);
  final grandCoveredLines = files.fold<int>(0, (sum, f) => sum + f.coveredLines);
  final overallPercentage = grandTotalLines > 0 ? (grandCoveredLines / grandTotalLines) * 100 : 0.0;

  final htmlContent = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>FashioMe - Test Coverage Report</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Montserrat:ital,wght@0,300;0,400;0,600;0,700;1,400&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg-color: #0B0B0C;
      --card-bg: #121215;
      --card-border: #1E1E24;
      --text-main: #FFFFFF;
      --text-muted: #8E8E93;
      --gold: #D4AF37;
      --gold-glow: rgba(212, 175, 55, 0.15);
      
      --success: #32D74B;
      --warning: #FF9F0A;
      --error: #FF453A;
      
      --success-bg: rgba(50, 215, 75, 0.1);
      --warning-bg: rgba(255, 159, 10, 0.1);
      --error-bg: rgba(255, 69, 58, 0.1);
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      font-family: 'Montserrat', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background-color: var(--bg-color);
      color: var(--text-main);
      line-height: 1.6;
      padding: 2rem 1.5rem;
    }

    .container {
      max-width: 1200px;
      margin: 0 auto;
    }

    header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 2.5rem;
      border-bottom: 1px solid var(--card-border);
      padding-bottom: 1.5rem;
    }

    .brand {
      display: flex;
      flex-direction: column;
    }

    .brand h1 {
      font-size: 2.2rem;
      font-weight: 700;
      letter-spacing: 2px;
      color: var(--text-main);
      text-transform: uppercase;
    }

    .brand h1 span {
      color: var(--gold);
      text-shadow: 0 0 10px var(--gold-glow);
    }

    .brand p {
      font-size: 0.9rem;
      color: var(--text-muted);
      margin-top: 0.2rem;
    }

    .timestamp {
      font-size: 0.85rem;
      color: var(--text-muted);
      background-color: var(--card-bg);
      padding: 0.5rem 1rem;
      border-radius: 20px;
      border: 1px solid var(--card-border);
    }

    /* Stats Grid */
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 1.5rem;
      margin-bottom: 3rem;
    }

    .stat-card {
      background-color: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 16px;
      padding: 1.5rem;
      position: relative;
      overflow: hidden;
      transition: all 0.3s ease;
    }

    .stat-card:hover {
      transform: translateY(-5px);
      border-color: var(--gold);
      box-shadow: 0 10px 20px rgba(0, 0, 0, 0.3);
    }

    .stat-card::before {
      content: '';
      position: absolute;
      top: 0;
      left: 0;
      width: 4px;
      height: 100%;
      background-color: var(--gold);
    }

    .stat-card.percentage::before {
      background-color: ${overallPercentage >= 80 ? 'var(--success)' : overallPercentage >= 50 ? 'var(--warning)' : 'var(--error)'};
    }

    .stat-label {
      font-size: 0.8rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: var(--text-muted);
      margin-bottom: 0.5rem;
    }

    .stat-value {
      font-size: 2.2rem;
      font-weight: 700;
    }

    .stat-value.percentage-val {
      color: ${overallPercentage >= 80 ? 'var(--success)' : overallPercentage >= 50 ? 'var(--warning)' : 'var(--error)'};
    }

    .stat-desc {
      font-size: 0.8rem;
      color: var(--text-muted);
      margin-top: 0.5rem;
    }

    /* Filter / Search Bar */
    .controls {
      display: flex;
      flex-direction: column;
      gap: 1rem;
      margin-bottom: 1.5rem;
      background-color: var(--card-bg);
      border: 1px solid var(--card-border);
      padding: 1.5rem;
      border-radius: 16px;
    }

    @media (min-width: 768px) {
      .controls {
        flex-direction: row;
        align-items: center;
        justify-content: space-between;
      }
    }

    .search-wrapper {
      position: relative;
      flex: 1;
      max-width: 400px;
    }

    .search-input {
      width: 100%;
      background-color: var(--bg-color);
      border: 1px solid var(--card-border);
      color: var(--text-main);
      padding: 0.8rem 1rem;
      border-radius: 8px;
      font-family: inherit;
      font-size: 0.9rem;
      transition: all 0.3s ease;
    }

    .search-input:focus {
      outline: none;
      border-color: var(--gold);
      box-shadow: 0 0 0 2px var(--gold-glow);
    }

    .filter-buttons {
      display: flex;
      gap: 0.5rem;
      flex-wrap: wrap;
    }

    .filter-btn {
      background-color: var(--bg-color);
      border: 1px solid var(--card-border);
      color: var(--text-muted);
      padding: 0.6rem 1.2rem;
      border-radius: 8px;
      font-family: inherit;
      font-size: 0.85rem;
      font-weight: 600;
      cursor: pointer;
      transition: all 0.3s ease;
    }

    .filter-btn:hover {
      border-color: var(--gold);
      color: var(--text-main);
    }

    .filter-btn.active {
      background-color: var(--gold);
      color: var(--bg-color);
      border-color: var(--gold);
    }

    /* File List Table */
    .table-container {
      background-color: var(--card-bg);
      border: 1px solid var(--card-border);
      border-radius: 16px;
      overflow: hidden;
      margin-bottom: 2rem;
      box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
    }

    table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
    }

    th, td {
      padding: 1.2rem 1.5rem;
      border-bottom: 1px solid var(--card-border);
    }

    th {
      font-size: 0.8rem;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1px;
      color: var(--text-muted);
      background-color: rgba(255, 255, 255, 0.02);
    }

    tr:last-child td {
      border-bottom: none;
    }

    tr:hover td {
      background-color: rgba(255, 255, 255, 0.01);
    }

    .file-path {
      font-weight: 600;
      font-size: 0.95rem;
    }

    .file-dir {
      color: var(--text-muted);
      font-weight: 400;
      font-size: 0.85rem;
    }

    .coverage-badge {
      display: inline-block;
      padding: 0.3rem 0.8rem;
      border-radius: 6px;
      font-size: 0.85rem;
      font-weight: 700;
      text-align: center;
      min-width: 70px;
    }

    .badge-success {
      background-color: var(--success-bg);
      color: var(--success);
    }

    .badge-warning {
      background-color: var(--warning-bg);
      color: var(--warning);
    }

    .badge-error {
      background-color: var(--error-bg);
      color: var(--error);
    }

    .progress-bar-container {
      width: 150px;
      height: 6px;
      background-color: rgba(255, 255, 255, 0.05);
      border-radius: 3px;
      overflow: hidden;
      display: inline-block;
      vertical-align: middle;
      margin-right: 1rem;
    }

    .progress-bar-fill {
      height: 100%;
      border-radius: 3px;
    }

    .progress-bar-fill.success { background-color: var(--success); }
    .progress-bar-fill.warning { background-color: var(--warning); }
    .progress-bar-fill.error { background-color: var(--error); }

    .numeric-stat {
      font-family: monospace;
      font-size: 0.9rem;
      color: var(--text-muted);
    }

    .no-results {
      padding: 3rem;
      text-align: center;
      color: var(--text-muted);
      display: none;
    }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <div class="brand">
        <h1>FashioMe <span>Coverage</span></h1>
        <p>Sprint 6 Unit & Widget Test Coverage Dashboard</p>
      </div>
      <div class="timestamp">
        Generated on: ${DateTime.now().toLocal().toString().substring(0, 19)}
      </div>
    </header>

    <div class="stats-grid">
      <div class="stat-card percentage">
        <div class="stat-label">Overall Coverage</div>
        <div class="stat-value percentage-val">${overallPercentage.toStringAsFixed(1)}%</div>
        <div class="stat-desc">Target coverage is 80%+</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Total Files</div>
        <div class="stat-value">${files.length}</div>
        <div class="stat-desc">Source files with coverage</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Covered Lines</div>
        <div class="stat-value">$grandCoveredLines</div>
        <div class="stat-desc">Executed lines during tests</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">Total Lines</div>
        <div class="stat-value">$grandTotalLines</div>
        <div class="stat-desc">Total executable lines</div>
      </div>
    </div>

    <div class="controls">
      <div class="search-wrapper">
        <input type="text" id="search" class="search-input" placeholder="Search files by name...">
      </div>
      <div class="filter-buttons">
        <button class="filter-btn active" onclick="filterCoverage('all')">All</button>
        <button class="filter-btn" onclick="filterCoverage('high')">High (>80%)</button>
        <button class="filter-btn" onclick="filterCoverage('medium')">Medium (50-80%)</button>
        <button class="filter-btn" onclick="filterCoverage('low')">Low (<50%)</button>
      </div>
    </div>

    <div class="table-container">
      <table id="coverage-table">
        <thead>
          <tr>
            <th>File</th>
            <th>Coverage Progress</th>
            <th>Percentage</th>
            <th>Lines</th>
          </tr>
        </thead>
        <tbody>
  ''';

  final buffer = StringBuffer(htmlContent);

  for (final file in files) {
    final pct = file.coveragePercentage;
    String badgeClass = '';
    String progressClass = '';
    if (pct >= 80) {
      badgeClass = 'badge-success';
      progressClass = 'success';
    } else if (pct >= 50) {
      badgeClass = 'badge-warning';
      progressClass = 'warning';
    } else {
      badgeClass = 'badge-error';
      progressClass = 'error';
    }

    final separatorIndex = file.filePath.lastIndexOf('/');
    final dir = separatorIndex != -1 ? file.filePath.substring(0, separatorIndex + 1) : '';
    final name = separatorIndex != -1 ? file.filePath.substring(separatorIndex + 1) : file.filePath;

    buffer.write('''
          <tr class="file-row" data-pct="$pct" data-name="${file.filePath.toLowerCase()}">
            <td>
              <div class="file-path">
                <span class="file-dir">$dir</span>$name
              </div>
            </td>
            <td>
              <div class="progress-bar-container">
                <div class="progress-bar-fill $progressClass" style="width: ${pct.toStringAsFixed(0)}%"></div>
              </div>
            </td>
            <td>
              <span class="coverage-badge $badgeClass">${pct.toStringAsFixed(1)}%</span>
            </td>
            <td class="numeric-stat">
              ${file.coveredLines}/${file.totalLines}
            </td>
          </tr>
    ''');
  }

  buffer.write('''
        </tbody>
      </table>
      <div id="no-results" class="no-results">
        No files match the search criteria.
      </div>
    </div>
  </div>

  <script>
    const searchInput = document.getElementById('search');
    const rows = document.querySelectorAll('.file-row');
    const noResults = document.getElementById('no-results');
    let currentFilter = 'all';

    searchInput.addEventListener('input', filterRows);

    function filterCoverage(filter) {
      currentFilter = filter;
      
      // Update active button
      document.querySelectorAll('.filter-btn').forEach(btn => {
        btn.classList.remove('active');
      });
      event.target.classList.add('active');

      filterRows();
    }

    function filterRows() {
      const query = searchInput.value.toLowerCase();
      let visibleCount = 0;

      rows.forEach(row => {
        const name = row.getAttribute('data-name');
        const pct = parseFloat(row.getAttribute('data-pct'));
        
        let matchesSearch = name.includes(query);
        let matchesFilter = false;

        if (currentFilter === 'all') {
          matchesFilter = true;
        } else if (currentFilter === 'high') {
          matchesFilter = pct >= 80;
        } else if (currentFilter === 'medium') {
          matchesFilter = pct >= 50 && pct < 80;
        } else if (currentFilter === 'low') {
          matchesFilter = pct < 50;
        }

        if (matchesSearch && matchesFilter) {
          row.style.display = '';
          visibleCount++;
        } else {
          row.style.display = 'none';
        }
      });

      if (visibleCount === 0) {
        noResults.style.display = 'block';
      } else {
        noResults.style.display = 'none';
      }
    }
  </script>
</body>
</html>
''');

  final outputFile = File('coverage/index.html');
  outputFile.writeAsStringSync(buffer.toString());
  print('HTML coverage report successfully generated at: \${outputFile.absolute.path}');
}

class FileCoverage {
  final String filePath;
  final int totalLines;
  final int coveredLines;
  final Map<int, int> lineHits;

  FileCoverage({
    required this.filePath,
    required this.totalLines,
    required this.coveredLines,
    required this.lineHits,
  });

  double get coveragePercentage => totalLines > 0 ? (coveredLines / totalLines) * 100 : 0.0;
}
