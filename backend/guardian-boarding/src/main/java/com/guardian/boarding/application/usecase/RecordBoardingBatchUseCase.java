package com.guardian.boarding.application.usecase;

import com.guardian.boarding.application.command.RecordBoardingCommand;
import com.guardian.boarding.application.port.BoardingEventRepository;
import com.guardian.boarding.application.result.BatchEventOutcome;
import com.guardian.boarding.domain.BoardingEvent;
import com.guardian.common.BusinessRule;
import com.guardian.common.error.BusinessRuleViolationException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;

/**
 * Accepts a queue of events a handset recorded while offline (BRD-004, ADR-0008).
 *
 * <p><strong>This path never rejects an event, and that is the whole point.</strong> BR-SAFE-005 🔴:
 * "Safety events recorded offline are never discarded. If they conflict with server state, they
 * are accepted and flagged for review."
 *
 * <p>The reasoning is worth stating, because it inverts the single-event path deliberately. Online,
 * a refusal is useful: the crew is standing in front of the child and can fix the problem now —
 * scan the right one, tap override, call the office. Offline, the event happened hours ago. The
 * child boarded; refusing the record does not un-board them, it only destroys the evidence that
 * they did. So every conflict here becomes a written, flagged row and a person's problem, not a
 * 422 and a lost fact.
 *
 * <p><strong>Each event commits on its own.</strong> This method is deliberately not
 * {@code @Transactional}: every call into {@link RecordBoardingEventUseCase} opens and commits its
 * own, and a refusal rolls back only that one. One bad event in a batch of forty must not discard
 * the thirty-nine good ones — a stop produces a dozen records in under two minutes, and a busload
 * syncing together is exactly the case this endpoint exists for.
 */
@Service
public class RecordBoardingBatchUseCase {

  private final RecordBoardingEventUseCase recordOne;
  private final FlaggedBoardingWriter flaggedWriter;
  private final BoardingEventRepository events;

  public RecordBoardingBatchUseCase(
      RecordBoardingEventUseCase recordOne,
      FlaggedBoardingWriter flaggedWriter,
      BoardingEventRepository events) {
    this.recordOne = recordOne;
    this.flaggedWriter = flaggedWriter;
    this.events = events;
  }

  @BusinessRule({"BR-BOARD-004", "BR-BOARD-008", "BR-BOARD-009", "BR-SAFE-005"})
  public List<BatchEventOutcome> execute(List<RecordBoardingCommand> commands) {
    List<BatchEventOutcome> outcomes = new ArrayList<>(commands.size());

    for (RecordBoardingCommand command : commands) {
      Optional<BoardingEvent> existing = events.findByClientEventId(command.clientEventId());
      if (existing.isPresent()) {
        outcomes.add(
            BatchEventOutcome.duplicate(command.clientEventId(), existing.get().id()));
        continue;
      }

      try {
        BoardingEvent recorded = recordOne.execute(command);
        outcomes.add(BatchEventOutcome.created(command.clientEventId(), recorded.id()));
      } catch (BusinessRuleViolationException refusal) {
        // The refusal is real, and the record is kept anyway. What the rule caught becomes the
        // reason a person reviewing it is shown.
        BoardingEvent flagged = flaggedWriter.write(command, refusal.errorCode().name());
        outcomes.add(
            BatchEventOutcome.flagged(
                command.clientEventId(),
                flagged.id(),
                refusal.errorCode().name()));
      }
    }

    return outcomes;
  }
}
