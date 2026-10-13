import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/auth.js';
import contentRoutes from './routes/content.js';
import reviewRoutes from './routes/review.js';
import entitiesRoutes from './routes/entities.js';
import notificationsRoutes from './routes/notifications.js';
import searchRoutes from './routes/search.js';
import libraryRoutes from './routes/library.js';
import schoolsRoutes from './routes/schools.js';
import membersRoutes from './routes/members.js';
import mobileRoutes from './routes/mobile.js';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '25mb' }));

app.use('/api/auth', authRoutes);
app.use('/api/content', contentRoutes);
app.use('/api/review', reviewRoutes);
app.use('/api/entities', entitiesRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/library', libraryRoutes);
app.use('/api/schools', schoolsRoutes);
app.use('/api/members', membersRoutes);
app.use('/api/mobile', mobileRoutes);

app.get('/api/health', (_, res) => res.json({ ok: true }));

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => console.log(`e-Muongozo backend on :${PORT}`));
