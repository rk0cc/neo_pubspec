/// Adding deep clone ability to [PubspecInfo], [PackageDependency] and
/// [PackageDependencySetFactory]
library neo_pubspec.cloner;

import 'package:neo_pubspec/neo_pubspec.dart';

export 'src/structre/structre.dart'
    show
        GitPackageDependencyCloner,
        PubspecInfoCloner,
        PackageDependencySetCloner,
        SDKPackageDependencyCloner,
        LocalPackageDependencyCloner,
        HostedPackageDependencyCloner,
        OverridePackageDependencySetCloner,
        ThirdPartyHostedPackageDependencyCloner;
