import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_fonts.dart';
import '../core/locale/plural.dart';
import '../core/models/app_models.dart';
import '../theme/app_colors.dart';
import 'design_system.dart'
    show
        AppCorners,
        AppGradients,
        AppRowCard,
        AppRowMeta,
        AppRowMetaLine,
        AppRowTitle,
        BidiText,
        BrandBannerPattern,
        CourseAuroraSpec,
        CourseCardMetrics,
        CoursePosterSpec,
        CourseTicketSpec;
import '../theme/app_motion.dart';
import 'course_favorite_button.dart';
import 'course_image_hero.dart';

part 'app_widgets/course_helpers.dart';
part 'app_widgets/common_widgets.dart';
part 'app_widgets/course_card.dart';
part 'app_widgets/course_poster_card.dart';
part 'app_widgets/course_boarding_card.dart';
part 'app_widgets/course_aurora_card.dart';
part 'app_widgets/course_row_card.dart';
