import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/web_resources/presentation/bloc/web_resources_bloc.dart';

class WebResourceCard extends StatefulWidget {
  final WebResource resource;
  final bool isAdmin;
  final VoidCallback? onFavorite;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const WebResourceCard({
    super.key,
    required this.resource,
    this.isAdmin = false,
    this.onFavorite,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<WebResourceCard> createState() => _WebResourceCardState();
}

class _WebResourceCardState extends State<WebResourceCard> {
  bool _hovered = false;

  String? get _displayImage {
    if (widget.resource.imageUrl != null && widget.resource.imageUrl!.isNotEmpty) {
      return widget.resource.imageUrl;
    }
    if (widget.resource.faviconUrl != null && widget.resource.faviconUrl!.isNotEmpty) {
      return widget.resource.faviconUrl;
    }
    return null;
  }

  bool get _isFavicon => _displayImage == widget.resource.faviconUrl;

  Future<void> _openUrl() async {
    final uri = Uri.parse(widget.resource.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered ? AppColors.primary.withOpacity(0.3) : AppColors.border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _openUrl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.resource.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (widget.resource.isFavorite)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.star, size: 16, color: Colors.amber),
                          ),
                        if (widget.isAdmin)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.textSecondary),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onSelected: (value) {
                              if (value == 'edit') widget.onEdit?.call();
                              if (value == 'favorite') widget.onFavorite?.call();
                              if (value == 'delete') widget.onDelete?.call();
                            },
                            itemBuilder: (_) => [
                              if (widget.onEdit != null)
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [
                                    Icon(Icons.edit_outlined, size: 16),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ]),
                                ),
                              const PopupMenuItem(
                                value: 'favorite',
                                child: Row(children: [
                                  Icon(Icons.favorite_border, size: 16),
                                  SizedBox(width: 8),
                                  Text('Favorite'),
                                ]),
                              ),
                              if (widget.onDelete != null)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [
                                    Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ]),
                                ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (widget.resource.description != null &&
                        widget.resource.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          widget.resource.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.resource.domain ??
                                (widget.resource.url
                                    .replaceFirst('https://', '')
                                    .replaceFirst('http://', '')
                                    .split('/')[0]),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (widget.resource.category != null &&
                            widget.resource.category!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.resource.category!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final imageUrl = _displayImage;
    if (imageUrl == null) {
      return Container(
        height: 120,
        width: double.infinity,
        color: AppColors.surface,
        child: const Center(
          child: Icon(Icons.language, size: 32, color: AppColors.textSecondary),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      height: 120,
      width: double.infinity,
      fit: _isFavicon ? BoxFit.contain : BoxFit.cover,
      placeholder: (context, url) => Container(
        height: 120,
        color: AppColors.surface,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: 120,
        color: AppColors.surface,
        child: const Center(
          child: Icon(Icons.language, size: 32, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
