import { createRouter, createWebHashHistory } from 'vue-router';
import Login from './views/Login.vue';
import Register from './views/Register.vue';
import EntityLogin from './views/EntityLogin.vue';
import Dashboard from './views/Dashboard.vue';
import TieDashboard from './views/TieDashboard.vue';
import NectaDashboard from './views/NectaDashboard.vue';
import TieMembers from './views/TieMembers.vue';
import TieRegisteredSchools from './views/TieRegisteredSchools.vue';
import NectaMembers from './views/NectaMembers.vue';
import NectaPendingSchools from './views/NectaPendingSchools.vue';
import NectaRegisteredSchools from './views/NectaRegisteredSchools.vue';
import Upload from './views/Upload.vue';
import Review from './views/Review.vue';
import MyContent from './views/MyContent.vue';
import Profile from './views/Profile.vue';
import Notifications from './views/Notifications.vue';
import ReadContent from './views/ReadContent.vue';

const routes = [
  { path: '/', redirect: '/login' },
  { path: '/login', component: Login },
  { path: '/register', component: Register },
  { path: '/entity/:type', component: EntityLogin },

  { path: '/dashboard', component: Dashboard, meta: { auth: true, roles: ['SCHOOL', 'REVIEWER'] } },

  // TIE
  { path: '/tie', component: TieDashboard, meta: { auth: true, roles: ['TIE', 'TIESTAFF'] } },
  { path: '/tie/members', component: TieMembers, meta: { auth: true, roles: ['TIE'] } },
  { path: '/tie/registered', component: TieRegisteredSchools, meta: { auth: true, roles: ['TIE'] } },

  // NECTA
  { path: '/necta', component: NectaDashboard, meta: { auth: true, roles: ['NECTA'] } },
  { path: '/necta/pending', component: NectaPendingSchools, meta: { auth: true, roles: ['NECTA'] } },
  { path: '/necta/registered', component: NectaRegisteredSchools, meta: { auth: true, roles: ['NECTA'] } },
  { path: '/necta/members', component: NectaMembers, meta: { auth: true, roles: ['NECTA'] } },

  { path: '/upload', component: Upload, meta: { auth: true, roles: ['TIE', 'TIESTAFF', 'NECTA', 'SCHOOL'] } },
  { path: '/my-content', component: MyContent, meta: { auth: true, roles: ['TIE', 'TIESTAFF', 'NECTA', 'SCHOOL'] } },
  { path: '/review', component: Review, meta: { auth: true, roles: ['REVIEWER'] } },
  { path: '/profile', component: Profile, meta: { auth: true } },
  { path: '/notifications', component: Notifications, meta: { auth: true } },

  { path: '/read/:id', component: ReadContent, meta: { auth: true } },
];

const router = createRouter({
  history: createWebHashHistory(),
  routes,
});

router.beforeEach((to) => {
  const token = localStorage.getItem('token');
  let user = null;
  try { user = JSON.parse(localStorage.getItem('user') || 'null'); } catch {}
  const role = user?.role ? String(user.role).toUpperCase() : null;

  if (to.meta.auth && !token) return '/login';
  if (to.meta.roles && role && !to.meta.roles.includes(role)) {
    const sharedPaths = ['/upload', '/my-content', '/profile', '/notifications'];
    const isShared = sharedPaths.includes(to.path) || to.path.startsWith('/read/');
    if (isShared) return true;
    if ((role === 'TIE' || role === 'TIESTAFF') && !to.path.startsWith('/tie')) return '/tie';
    if (role === 'NECTA' && !to.path.startsWith('/necta')) return '/necta';
    if (role === 'SCHOOL' && to.path !== '/dashboard') return '/dashboard';
    if (role === 'REVIEWER' && to.path !== '/dashboard' && to.path !== '/review') return '/dashboard';
  }
});

export default router;
