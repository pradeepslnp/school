package com.guardian.parent.interfaces.rest;

import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.parent.application.result.ChildDetailView;
import com.guardian.parent.application.result.DashboardView;
import com.guardian.parent.application.result.JourneyHistoryView;
import com.guardian.parent.application.usecase.GetChildDetailUseCase;
import com.guardian.parent.application.usecase.GetJourneyHistoryUseCase;
import com.guardian.parent.application.usecase.GetMyChildrenUseCase;
import com.guardian.parent.domain.JourneyHistoryEntry;
import com.guardian.parent.domain.JourneyLeg;
import com.guardian.parent.interfaces.rest.dto.ResponseMeta;
import com.guardian.parent.interfaces.rest.dto.StudentJourneyResource;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * The parent app's read surface — features GRD-007 and STU-001, screens P-02 and P-03.
 *
 * <p>Both endpoints are scoped to the caller's own children (BR-IAM-005), and that scope is
 * enforced inside the projection rather than here: no student identifier the client sends can widen
 * it, and {@code GET /guardians/me/students} accepts no identifier at all. An endpoint that took a
 * guardian id would be an endpoint that could be asked about somebody else's child.
 *
 * <p>{@code PERM-STUDENT-VIEW} is the declared permission, per the permission matrix: the same
 * permission staff hold, with the scope narrowed to {@code OWN_CHILDREN} for a guardian. Holding it
 * is necessary and never sufficient.
 *
 * <p>These controllers build the full envelope themselves — {@code data} plus {@code meta} —
 * because {@code meta.school} is required here and the global advice cannot know about a school.
 * {@code ResponseEnvelopeAdvice} leaves any body already carrying {@code data} untouched.
 */
@RestController
@RequestMapping("/api/v1/guardians/me/students")
public class ParentStudentsController {

  private final GetMyChildrenUseCase getMyChildren;
  private final GetChildDetailUseCase getChildDetail;
  private final GetJourneyHistoryUseCase getJourneyHistory;

  public ParentStudentsController(
      GetMyChildrenUseCase getMyChildren,
      GetChildDetailUseCase getChildDetail,
      GetJourneyHistoryUseCase getJourneyHistory) {
    this.getMyChildren = getMyChildren;
    this.getChildDetail = getChildDetail;
    this.getJourneyHistory = getJourneyHistory;
  }

  /**
   * P-02 — every child, with current journey state inline.
   *
   * <p>Inline rather than composable from {@code /trips/{id}/position} per child: that fan-out is
   * an N+1 over mobile data at the exact moment the answer matters most
   * (guardian-docs/04-api/STUDENTS_GUARDIANS_API.md).
   */
  @GetMapping
  @RequiresPermission("PERM-STUDENT-VIEW")
  public Map<String, Object> myChildren(CurrentActor actor) {
    DashboardView view = getMyChildren.execute(actor.userId());

    List<StudentJourneyResource> data = new ArrayList<>(view.children().size());
    view.children().forEach(child -> data.add(StudentJourneyResource.from(child)));

    return envelope(data, ResponseMeta.of(view.clock(), view.observedAt()));
  }

  /**
   * P-03 — one child in full: the same journey state, plus today's legs.
   *
   * <p>A student outside the caller's scope is refused with {@code 403 AUTH_SCOPE_DENIED}, not
   * {@code 404}. Within a tenant that is the honest answer; {@code 404} would let a caller probe
   * for which children exist (guardian-docs/04-api/API_STANDARDS.md § 403 vs 404).
   */
  @GetMapping("/{studentId}")
  @RequiresPermission("PERM-STUDENT-VIEW")
  public Map<String, Object> childDetail(@PathVariable UUID studentId, CurrentActor actor) {
    ChildDetailView view = getChildDetail.execute(actor.userId(), studentId);

    StudentJourneyResource resource = StudentJourneyResource.from(view.journey());
    List<Map<String, Object>> legs = new ArrayList<>(view.legs().size());
    view.legs().forEach(leg -> legs.add(legResource(leg)));

    Map<String, Object> attributes = new LinkedHashMap<>(resource.attributes());
    attributes.put("legs", legs);

    Map<String, Object> data = new LinkedHashMap<>();
    data.put("id", resource.id());
    data.put("type", resource.type());
    data.put("attributes", attributes);

    return envelope(data, ResponseMeta.of(view.clock(), view.observedAt()));
  }

  /**
   * P-05 — the durable record of past journeys, newest first.
   *
   * <p>{@code PERM-BOARDING-VIEW} rather than {@code PERM-STUDENT-VIEW}: this is the boarding
   * record, and a guardian's copy of it is scoped to their own children
   * (guardian-docs/05-ui/SCREEN_INVENTORY.md).
   *
   * <p>Carries {@code meta.school} like the dashboard does. {@code eventAt} is a UTC instant, and a
   * client rendering "boarded at 07:42" needs the school's zone to say that truthfully — without it
   * a parent abroad reads their own child's morning in the wrong hours (BR-CFG-006).
   */
  @GetMapping("/{studentId}/journey-history")
  @RequiresPermission("PERM-BOARDING-VIEW")
  public Map<String, Object> journeyHistory(@PathVariable UUID studentId, CurrentActor actor) {
    JourneyHistoryView view = getJourneyHistory.execute(actor.userId(), studentId);

    List<Map<String, Object>> data = new ArrayList<>(view.entries().size());
    view.entries().forEach(entry -> data.add(historyResource(entry)));

    return envelope(data, ResponseMeta.of(view.clock(), view.observedAt()));
  }

  private static Map<String, Object> historyResource(JourneyHistoryEntry entry) {
    Map<String, Object> map = new LinkedHashMap<>();
    // YYYY-MM-DD, per API_STANDARDS.md — a date, deliberately not an instant.
    map.put("serviceDate", entry.serviceDate().toString());
    map.put("direction", entry.direction().wireName());
    map.put("state", entry.state().wireName());
    putIfPresent(map, "vehicleDisplayName", entry.vehicleDisplayName());
    putIfPresent(map, "stopName", entry.stopName());
    putIfPresent(map, "eventAt", iso(entry.eventAt()));
    return map;
  }

  private static Map<String, Object> legResource(JourneyLeg leg) {
    Map<String, Object> map = new LinkedHashMap<>();
    map.put("direction", leg.direction().wireName());
    map.put("state", leg.state().wireName());
    putIfPresent(map, "vehicleDisplayName", leg.vehicleDisplayName());
    putIfPresent(map, "stopName", leg.stopName());
    putIfPresent(map, "scheduledAt", iso(leg.scheduledAt()));
    putIfPresent(map, "eventAt", iso(leg.eventAt()));
    return map;
  }

  private static Map<String, Object> envelope(Object data, Map<String, Object> meta) {
    Map<String, Object> body = new LinkedHashMap<>();
    body.put("data", data);
    body.put("meta", meta);
    return body;
  }

  private static void putIfPresent(Map<String, Object> target, String key, Object value) {
    if (value != null) {
      target.put(key, value);
    }
  }

  private static String iso(Instant value) {
    return value == null ? null : value.toString();
  }
}
