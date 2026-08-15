
import '../models/endower_reference.dart';
import '../models/endowment_reference.dart';
import '../models/waqf_reference_bundle.dart';

abstract class WaqfReferenceRepository {
  Future<WaqfReferenceBundle?> getReferenceBundle(String idOrPwf);
  Future<EndowmentReference?> getEndowmentByIdOrKey(String idOrPwf);
  Future<EndowerReference?> getEndowerById(String id);
  Future<List<EndowmentReference>> searchEndowments({String? query, int limit = 40});
}
