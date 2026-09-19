package com.guardian.student.interfaces.rest;

import com.guardian.common.rest.CursorPage;
import com.guardian.common.security.CallerAccess;
import com.guardian.common.security.CurrentActor;
import com.guardian.common.security.RequiresPermission;
import com.guardian.student.application.command.CreateStudentCommand;
import com.guardian.student.application.command.UpdateStudentCommand;
import com.guardian.student.application.port.StudentPage;
import com.guardian.student.application.usecase.CreateStudentUseCase;
import com.guardian.student.application.usecase.DiscardStudentUseCase;
import com.guardian.student.application.usecase.GetStudentUseCase;
import com.guardian.student.application.usecase.UpdateStudentUseCase;
import com.guardian.student.application.usecase.WithdrawStudentUseCase;
import com.guardian.student.domain.AdmissionNumber;
import com.guardian.student.domain.BranchId;
import com.guardian.student.domain.SchoolId;
import com.guardian.student.domain.Student;
import com.guardian.student.domain.StudentClassId;
import com.guardian.student.domain.StudentId;
import com.guardian.student.interfaces.rest.dto.CreateStudentRequest;
import com.guardian.student.interfaces.rest.dto.DiscardStudentRequest;
import com.guardian.student.interfaces.rest.dto.StudentResponse;
import com.guardian.student.interfaces.rest.dto.UpdateStudentRequest;
import com.guardian.student.interfaces.rest.dto.WithdrawStudentRequest;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Student endpoints (features STU-001, STU-004, STU-008). See
 * guardian-docs/04-api/STUDENTS_GUARDIANS_API.md.
 *
 * <p>Every method declares a permission from the permission matrix, and the declaration is now
 * enforced at request time as well as at build time.
 *
 * <p>This layer only translates: parse the wire format into domain types, call one use case, map
 * the result back. No business logic, no repository access.
 */
@RestController
@RequestMapping("/api/v1/students")
public class StudentController {

  /** API_STANDARDS.md: default 50, maximum 200. */
  private static final int DEFAULT_LIMIT = 50;

  private static final int MAX_LIMIT = 200;

  private final CreateStudentUseCase createStudent;
  private final GetStudentUseCase getStudent;
  private final UpdateStudentUseCase updateStudent;
  private final WithdrawStudentUseCase withdrawStudent;
  private final DiscardStudentUseCase discardStudent;

  public StudentController(
      CreateStudentUseCase createStudent,
      GetStudentUseCase getStudent,
      UpdateStudentUseCase updateStudent,
      WithdrawStudentUseCase withdrawStudent,
      DiscardStudentUseCase discardStudent) {
    this.createStudent = createStudent;
    this.getStudent = getStudent;
    this.updateStudent = updateStudent;
    this.withdrawStudent = withdrawStudent;
    this.discardStudent = discardStudent;
  }

  @PostMapping
  @RequiresPermission("PERM-STUDENT-CREATE")
  public ResponseEntity<StudentResponse> create(
      @Valid @RequestBody CreateStudentRequest request, CurrentActor actor) {

    CreateStudentCommand command =
        new CreateStudentCommand(
            SchoolId.of(request.schoolId()),
            request.branchId() == null ? null : BranchId.of(request.branchId()),
            request.studentClassId() == null ? null : StudentClassId.of(request.studentClassId()),
            AdmissionNumber.of(request.admissionNo()),
            request.firstName(),
            request.lastName(),
            request.dateOfBirth(),
            request.transportEligibleOrDefault(),
            actor.userId(),
            actor.role());

    Student created = createStudent.execute(command);

    return ResponseEntity.created(URI.create("/api/v1/students/" + created.id()))
        .body(StudentResponse.from(created));
  }

  @GetMapping("/{studentId}")
  @RequiresPermission("PERM-STUDENT-VIEW")
  public StudentResponse getById(@PathVariable UUID studentId, CurrentActor actor) {
    return StudentResponse.from(getStudent.byId(StudentId.of(studentId), actor));
  }

  /**
   * One page of a school's register (screen A-10).
   *
   * <p>Paged rather than returned whole: a school has thousands of students, and DEFINITION_OF_DONE
   * §8 requires every query bounded. {@code limit} is clamped rather than rejected — a client
   * asking for more than the maximum wants as much as it can have, and a 400 there would be
   * pedantry.
   */
  @GetMapping
  @RequiresPermission("PERM-STUDENT-VIEW")
  public CursorPage<StudentResponse> listBySchool(
      @RequestParam UUID schoolId,
      @RequestParam(required = false) String cursor,
      @RequestParam(required = false) Integer limit,
      CurrentActor actor) {

    int effectiveLimit = clamp(limit);
    StudentPage page = getStudent.bySchool(SchoolId.of(schoolId), cursor, effectiveLimit, actor);

    List<StudentResponse> students = page.students().stream().map(StudentResponse::from).toList();

    return CursorPage.of(students, page.nextCursor(), effectiveLimit);
  }

  @PatchMapping("/{studentId}")
  @RequiresPermission("PERM-STUDENT-EDIT")
  public StudentResponse update(
      @PathVariable UUID studentId,
      @Valid @RequestBody UpdateStudentRequest request,
      CurrentActor actor) {

    UpdateStudentCommand command =
        new UpdateStudentCommand(
            StudentId.of(studentId),
            request.firstName(),
            request.lastName(),
            request.dateOfBirth(),
            request.branchId() == null ? null : BranchId.of(request.branchId()),
            request.studentClassId() == null ? null : StudentClassId.of(request.studentClassId()),
            request.transportEligibleOrDefault(),
            actor.userId(),
            actor.role());

    return StudentResponse.from(updateStudent.execute(command));
  }

  /**
   * Takes the student off the roll (feature STU-004).
   *
   * <p>A POST to a named transition rather than a DELETE: nothing is deleted, and BR-STU-005 means
   * nothing ever can be while safety records reference the child.
   */
  @PostMapping("/{studentId}/withdraw")
  @RequiresPermission("PERM-STUDENT-EDIT")
  public StudentResponse withdraw(
      @PathVariable UUID studentId,
      @Valid @RequestBody(required = false) WithdrawStudentRequest request,
      CurrentActor actor) {

    String reason = request == null ? null : request.reason();

    return StudentResponse.from(
        withdrawStudent.execute(StudentId.of(studentId), actor.userId(), actor.role(), reason));
  }

  /**
   * Permanently removes a student entered by mistake (feature STU-008, BR-STU-007). A named {@code
   * POST} rather than {@code DELETE}: {@code DELETE} never hard-deletes on this platform, and a
   * {@code POST} is not retried by clients (ADR-0019). Refused if the student has any history.
   */
  @PostMapping("/{studentId}/discard")
  @RequiresPermission("PERM-STUDENT-DELETE")
  public ResponseEntity<Void> discard(
      @PathVariable UUID studentId,
      @Valid @RequestBody DiscardStudentRequest request,
      CurrentActor actor,
      CallerAccess access) {

    discardStudent.execute(
        StudentId.of(studentId), request.reason(), access.scope(), actor.userId(), actor.role());
    return ResponseEntity.noContent().build();
  }

  private static int clamp(Integer requested) {
    if (requested == null || requested < 1) {
      return DEFAULT_LIMIT;
    }
    return Math.min(requested, MAX_LIMIT);
  }
}
