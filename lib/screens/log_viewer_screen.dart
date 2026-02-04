import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/logger_service.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({Key? key}) : super(key: key);

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  final LoggerService _logger = LoggerService();
  late TextEditingController _searchController;
  String _selectedFilter = 'ALL';
  List<LogEntry> _displayedLogs = [];

  final List<String> _filterOptions = [
    'ALL',
    'DEBUG',
    'INFO',
    'WARNING',
    'ERROR',
    'API_REQUEST',
    'API_RESPONSE',
    'API_ERROR',
    'AUTH_EVENT',
    'USER_ACTION',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _refreshLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshLogs() {
    setState(() {
      _displayedLogs = _logger.getLogHistory();
      _applyFilter();
    });
  }

  void _applyFilter() {
    setState(() {
      if (_selectedFilter == 'ALL') {
        if (_searchController.text.isEmpty) {
          _displayedLogs = _logger.getLogHistory();
        } else {
          _displayedLogs = _logger.searchLogs(_searchController.text);
        }
      } else {
        final filtered = _logger
            .getLogHistory()
            .where((log) => log.level == _selectedFilter)
            .toList();

        if (_searchController.text.isEmpty) {
          _displayedLogs = filtered;
        } else {
          _displayedLogs = filtered
              .where((log) => log.message
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()))
              .toList();
        }
      }
    });
  }

  Future<void> _exportLogs() async {
    try {
      final logContent = await _logger.getLogFileContent();
      final logPath = await _logger.getLogFilePath();

      await Share.shareXFiles(
        [XFile(logPath)],
        text: 'App Logs',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export logs: $e')),
      );
    }
  }

  Future<void> _clearLogs() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text('Are you sure you want to clear all logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _logger.clearLogs();
              Navigator.pop(context);
              _refreshLogs();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logs cleared')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'ERROR':
      case 'API_ERROR':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      case 'DEBUG':
        return Colors.grey;
      case 'API_REQUEST':
        return Colors.blue;
      case 'API_RESPONSE':
        return Colors.green;
      case 'AUTH_EVENT':
        return Colors.purple;
      case 'USER_ACTION':
        return Colors.cyan;
      default:
        return Colors.black;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'ERROR':
      case 'API_ERROR':
        return Icons.error;
      case 'WARNING':
        return Icons.warning;
      case 'DEBUG':
        return Icons.bug_report;
      case 'API_REQUEST':
        return Icons.upload;
      case 'API_RESPONSE':
        return Icons.download;
      case 'AUTH_EVENT':
        return Icons.lock;
      case 'USER_ACTION':
        return Icons.person;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            )),
        title: const Text('Log Viewer'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLogs,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportLogs,
            tooltip: 'Export Logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLogs,
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search logs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilter();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (_) => _applyFilter(),
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedFilter = filter);
                        _applyFilter();
                      },
                      selectedColor: Colors.blueAccent,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Log Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Total Logs: ${_displayedLogs.length}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),

          // Logs List
          Expanded(
            child: _displayedLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No logs found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _displayedLogs.length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      final log = _displayedLogs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: Icon(
                              _getLevelIcon(log.level),
                              color: _getLevelColor(log.level),
                            ),
                            title: Text(
                              log.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '[${log.level}] ${log.formattedTime}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _getLevelColor(log.level),
                                  ),
                                ),
                                if (log.errorDetails != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Error: ${log.errorDetails}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: log.isError
                                ? const Icon(Icons.error, color: Colors.red)
                                : (log.isWarning
                                    ? const Icon(Icons.warning,
                                        color: Colors.orange)
                                    : null),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('[${log.level}] Details'),
                                  content: SingleChildScrollView(
                                    child: SelectableText(
                                      '''Timestamp: ${log.formattedFullTime}
Level: ${log.level}
Message: ${log.message}
${log.errorDetails != null ? 'Error: ${log.errorDetails}' : ''}
${log.details != null ? 'Details: ${log.details}' : ''}''',
                                      style: const TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
