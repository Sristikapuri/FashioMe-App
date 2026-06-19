import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fashio_me/features/silhouette/presentation/state/silhouette_flow_state.dart';
import 'package:fashio_me/features/silhouette/presentation/view_model/silhouette_flow_view_model.dart';

final silhouetteFlowViewModelProvider =
    NotifierProvider<SilhouetteFlowViewModel, SilhouetteFlowState>(
      SilhouetteFlowViewModel.new,
    );
