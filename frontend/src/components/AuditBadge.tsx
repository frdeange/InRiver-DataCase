interface AuditBadgeProps {
  blocked: boolean
  riskLevel: string
  blockReason: string | null
  guardrailPassed: boolean
}

export default function AuditBadge({
  blocked,
  riskLevel,
  blockReason,
  guardrailPassed,
}: AuditBadgeProps) {
  if (blocked) {
    return (
      <div className="badge badge-red">
        <span className="badge-label">BLOCKED</span>
        {blockReason && <span className="badge-reason">{blockReason}</span>}
      </div>
    )
  }

  if (riskLevel === 'low') {
    return (
      <div className="badge badge-yellow">
        <span className="badge-label">LOW RISK</span>
      </div>
    )
  }

  if (riskLevel === 'none' && guardrailPassed) {
    return (
      <div className="badge badge-green">
        <span className="badge-label">ALLOWED</span>
      </div>
    )
  }

  return (
    <div className="badge badge-grey">
      <span className="badge-label">{riskLevel.toUpperCase() || 'UNKNOWN'}</span>
    </div>
  )
}
