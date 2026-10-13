/**
 * Single source of truth for role-specific configuration.
 * Adding a new role = one entry here + a new dashboard route.
 */

export const roles = {
  TIE: {
    variant: 'TIE',
    dashboardPath: '/tie',
    label: 'TIE Contributor',

    // Upload page
    pageTitle: 'Upload Curriculum',
    roleHint: 'Your content publishes immediately with a TIE-Official badge.',
    badge: 'TIE-Official',
    submitLabel: 'Publish Now',

    // Catalog (pull source)
    catalog: {
      source: 'tie',
      title: 'TIE Library',
      subtitle: 'Official curriculum sources — pull to publish',
      realSource: 'TIE',
      types: ['Syllabus', 'Textbook'],
      // Sync tab labels
      syncTitle: 'TIE System',
      syncSubtitle: 'Direct sync from TIE systems',
      syncEndpointLabel: 'TIE endpoint',
      syncEndpoints: [
        { value: 'syllabus', label: 'Core Syllabus (2024)' },
        { value: 'textbooks', label: 'Official Textbooks' },
        { value: 'competency', label: 'Competency Framework' },
      ],
      // Whether to show this tab at all
      showCatalogTab: true,
      showSyncTab: true,
    },
  },

  NECTA: {
    variant: 'NECTA',
    dashboardPath: '/necta',
    label: 'NECTA Contributor',

    pageTitle: 'Upload Report',
    roleHint: 'Your content publishes immediately with a NECTA-Official badge.',
    badge: 'NECTA-Official',
    submitLabel: 'Publish Now',

    catalog: {
      source: 'necta',
      title: 'NECTA Archive',
      subtitle: 'Past papers, SIRA diagnostics, and answering schemes',
      realSource: 'NECTA',
      types: ['Past Paper', 'SIRA Report', 'Answering Scheme'],
      syncTitle: 'NECTA System',
      syncSubtitle: 'Direct sync from NECTA systems',
      syncEndpointLabel: 'NECTA endpoint',
      syncEndpoints: [
        { value: 'past-papers', label: 'Past Papers Archive' },
        { value: 'sira', label: 'SIRA Diagnostics' },
        { value: 'schemes', label: 'Answering Schemes' },
      ],
      showCatalogTab: true,
      showSyncTab: true,
    },
  },

  SCHOOL: {
    variant: 'SCHOOL',
    dashboardPath: '/dashboard',
    label: 'School Contributor',

    pageTitle: 'Upload Content',
    roleHint: 'Your content goes to the TIE review queue. Once approved, it gets a TIE-Reviewed badge.',
    badge: 'Pending',
    submitLabel: 'Submit for Review',

    catalog: {
      source: 'approved',
      title: 'Approved Library',
      subtitle: 'Verified content you can reference',
      realSource: 'e-Muongozo',
      types: ['Guide', 'Reference'],
      syncTitle: 'Sync',
      syncSubtitle: 'Sync with the central library',
      syncEndpointLabel: 'Source',
      syncEndpoints: [],
      // Schools don't need to pull from TIE/NECTA — they consume approved content
      showCatalogTab: false,
      showSyncTab: false,
    },
  },

  REVIEWER: {
    variant: 'REVIEWER',
    dashboardPath: '/dashboard',
    label: 'TIE Reviewer',

    pageTitle: 'Upload',
    roleHint: 'Reviewers do not upload content.',
    badge: 'Pending',
    submitLabel: 'Submit',

    catalog: {
      source: 'approved',
      title: 'Approved Library',
      subtitle: 'Content ready for review',
      realSource: 'e-Muongozo',
      types: ['Guide', 'Reference'],
      syncTitle: 'Sync',
      syncSubtitle: '',
      syncEndpointLabel: 'Source',
      syncEndpoints: [],
      showCatalogTab: false,
      showSyncTab: false,
    },
  },
};

export function getRoleConfig(role) {
  return roles[role] || roles.SCHOOL;
}

export function getMaskedEmail(email) {
  if (!email) return '';
  const [name, domain] = email.split('@');
  if (!name || !domain) return email;
  const masked = name.length > 2
    ? name[0] + '*'.repeat(Math.min(4, name.length - 2)) + name[name.length - 1]
    : '*'.repeat(name.length);
  return `${masked}@${domain}`;
}
