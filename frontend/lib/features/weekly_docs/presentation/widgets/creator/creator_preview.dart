import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/doc_creator_cubit.dart';
import '../preview_pane.dart';

/// Khung xem trước của màn soạn (cột phải, hoặc bottom sheet ở màn hẹp); tô vàng khối đang sửa.
class CreatorPreview extends StatelessWidget {
  const CreatorPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DocCreatorCubit>().state;
    final cubit = context.read<DocCreatorCubit>();
    return PreviewPane(
      doc: state.doc,
      view: state.previewView,
      slideIndex: state.previewIndex,
      onViewChanged: cubit.setPreviewView,
      onSlideChanged: cubit.setPreviewIndex,
      highlightKey: state.highlightKey,
    );
  }
}
