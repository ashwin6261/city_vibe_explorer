import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/place.dart';

/// Swipe-up rich modal bottom sheet showcasing visual photo, must-try food,
/// opening hours, and one-tap turn-by-turn navigation in Google Maps.
class PlaceDetailModal extends StatelessWidget {
  final Place place;

  const PlaceDetailModal({super.key, required this.place});

  static void show(BuildContext context, Place place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlaceDetailModal(place: place),
    );
  }

  Future<void> _launchGoogleMapsNavigation(BuildContext context) async {
    final lat = place.latitude;
    final lng = place.longitude;
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    String? error;
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        error = 'Could not open Google Maps on this device.';
      }
    } catch (e) {
      error = 'Navigation failed: $e';
    }
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> _open(BuildContext context, String url) async {
    try {
      final launched =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link on this device.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link on this device.')),
        );
      }
    }
  }

  Widget _linkButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required String url,
  }) {
    return OutlinedButton.icon(
      onPressed: () => _open(context, url),
      icon: Icon(icon, color: color, size: 20),
      label: Text(label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header image with overlay tags
          Stack(
            children: [
              CachedNetworkImage(
                imageUrl: place.imageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 220,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 220,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(191),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.pinkAccent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Visual Index: ${place.visualScore}/100',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            place.category,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${place.rating}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),

                // Must-try highlight box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.deepOrange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.restaurant_menu_rounded, color: Colors.deepOrange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MUST-TRY & PHOTO HIGHLIGHT',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                            ),
                            Text(
                              place.mustTry,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Videos (YouTube / Facebook)
                const Text(
                  'VIDEOS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _linkButton(
                        context,
                        icon: Icons.play_circle_fill,
                        label: 'YouTube',
                        color: Colors.red,
                        url: place.videoUrl ??
                            'https://www.youtube.com/results?search_query=${Uri.encodeQueryComponent('${place.name} ${place.address}')}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _linkButton(
                        context,
                        icon: Icons.facebook,
                        label: 'Facebook',
                        color: Colors.blue,
                        url:
                            'https://www.facebook.com/search/videos/?q=${Uri.encodeQueryComponent(place.name)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  place.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),

                // Address & Hours
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18, color: Colors.blueAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        place.address,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      place.openingHours,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
                if (place.website != null && place.website!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.language, size: 18, color: Colors.purple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          place.website!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.open_in_new, size: 18),
                        onPressed: () => _open(context, place.website!),
                      ),
                    ],
                  ),
                ],
                if (place.phone != null && place.phone!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 18, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        place.phone!,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchGoogleMapsNavigation(context),
                    icon: const Icon(Icons.directions_rounded),
                    label: const Text(
                      'Navigate in Google Maps',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}