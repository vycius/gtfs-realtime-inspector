import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends StatelessWidget {
  static const _authorPageUrl = 'https://www.vycius.lt/';
  final String? gtfsUrl;
  final List<String> gtfsRealtimeUrls;

  const InfoPage({
    super.key,
    required this.gtfsUrl,
    required this.gtfsRealtimeUrls,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GTFS Realtime inspector'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            children: [
              if (gtfsUrl != null)
                ListTile(
                  leading: const Icon(Icons.archive),
                  title: const Text('GTFS'),
                  subtitle: Text(gtfsUrl!),
                  onTap: _downloadGTFS,
                  trailing: const Icon(Icons.download),
                ),
              for (final rt in gtfsRealtimeUrls)
                ListTile(
                  leading: const Icon(Icons.update),
                  title: const Text('GTFS Realtime'),
                  subtitle: Text(rt),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: gtfsUrl != null ? () => _openValidator(rt) : null,
                ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Karolis Vyčius'),
                subtitle: const Text('Author'),
                onTap: _openAuthorPage,
                trailing: const Icon(Icons.open_in_new),
              ),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('GitHub'),
                trailing: const Icon(Icons.open_in_new),
                onTap: _openGithubRepository,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _openValidator(String gtfsRealtimeUrl) {
    final queryParameters = {
      'url': gtfsUrl,
      'feed_url': gtfsRealtimeUrls,
      'type': 'gtfs-rt',
      'locale': 'en',
    };

    final uri = Uri.https(
      'transport.data.gouv.fr',
      '/validation',
      queryParameters,
    );

    return launchUrl(uri);
  }

  Future<bool> _openGithubRepository() {
    final uri = Uri.parse('https://github.com/vycius/gtfs-realtime-inspector');

    return launchUrl(uri);
  }

  Future<bool> _downloadGTFS() {
    return launchUrl(Uri.parse(gtfsUrl!));
  }

  Future<bool> _openAuthorPage() {
    return launchUrl(Uri.parse(_authorPageUrl));
  }
}
