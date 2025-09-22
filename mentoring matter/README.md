# Mentoring Matters - Complete Setup Instructions

## 🚀 Quick Start

### Prerequisites
- Node.js (v16+)
- MongoDB (local or MongoDB Atlas)

### 1. Backend Setup
```bash
cd server
npm install
```

### 2. Environment Configuration
Copy `.env.example` to `.env` and update:
```
MONGO_URI=mongodb://localhost:27017/mentoring-matters
# OR for MongoDB Atlas:
# MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/mentoring-matters
JWT_SECRET=your_super_secret_jwt_key_change_in_production
PORT=5000
```

### 3. Frontend Setup
```bash
cd client
npm install
```

### 4. Run the Application
Start backend:
```bash
cd server
node index.js
```

Start frontend (in new terminal):
```bash
cd client
npm start
```

## 🌟 Features Implemented

### ✅ Authentication & Security
- Email/password authentication
- JWT-based sessions
- Role-based access control (Admin/Mentor/Mentee)
- Secure password hashing with bcryptjs

### ✅ Database Structure
- User model with roles and organizations
- Pair model supporting many mentees per mentor
- Goal tracking with status (Not Started/In Progress/Completed)
- Session scheduling and notes
- Feedback system with 1-5 star ratings
- Materials sharing (URLs and documents)

### ✅ Admin Features
- User creation and role assignment
- Mentor-mentee pairing interface
- Comprehensive analytics dashboard:
  - Active pairs count
  - Total sessions
  - Average ratings
  - Goal progress (pie chart)
  - User distribution (bar chart)
- CSV export functionality
- Organization-based data filtering

### ✅ Mentor/Mentee Features
- **Goals Tab**: Create and track goals with status updates
- **Sessions Tab**: Schedule sessions with notes
- **Feedback Tab**: 1-5 star ratings + comments after sessions
- **Materials Tab**: Mentors can share URLs and documents
- **Privacy**: Users only see their own pair data

### ✅ Design & UI
- Light blue and white theme (#1976d2, #e3f2fd, #f5f9ff)
- Fully responsive design (mobile and desktop)
- Professional dashboard layout
- Sidebar navigation with role-specific features
- Modern styling with hover effects and transitions
- Loading states and error handling
- Clean typography and consistent spacing

## 📱 How to Use

### Initial Setup
1. Go to `http://localhost:3000`
2. Click "Sign Up" to create an account
3. Choose your role (Admin/Mentor/Mentee)
4. Enter organization name

### Admin Workflow
1. **Dashboard**: View analytics and overview
2. **User Management**: Create users and assign roles
3. **Pairing**: Create mentor-mentee pairs
4. **Analytics**: View charts and export CSV data

### Mentor/Mentee Workflow
1. **Goals**: Set and track progress on goals
2. **Sessions**: Schedule and record mentoring sessions
3. **Feedback**: Rate sessions and provide comments
4. **Materials**: Share/view helpful resources

## 🔧 API Endpoints

### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login

### Users (Admin only)
- `GET /api/users` - List all users
- `POST /api/users` - Create user
- `DELETE /api/users/:id` - Delete user

### Pairs
- `GET /api/pairs` - Get user's pairs
- `POST /api/pairs` - Create pair (admin)
- `PUT /api/pairs/:id` - Update pair (admin)
- `DELETE /api/pairs/:id` - Delete pair (admin)

### Goals
- `GET /api/goals` - Get goals for user's pairs
- `POST /api/goals` - Create goal
- `PUT /api/goals/:id` - Update goal status

### Sessions
- `GET /api/sessions` - Get sessions for user's pairs
- `POST /api/sessions` - Create session

### Feedback
- `GET /api/feedback` - Get feedback for user's sessions
- `POST /api/feedback` - Submit feedback

### Materials
- `GET /api/materials` - Get materials for user's pairs
- `POST /api/materials` - Share material (mentors only)

### Analytics (Admin only)
- `GET /api/analytics` - Get analytics data
- `GET /api/analytics/export` - Export CSV

## 🔒 Security Features
- JWT authentication with role-based access
- Password hashing with bcryptjs
- Organization-based data isolation
- Input validation and error handling
- CORS protection
- Secure HTTP headers

## 📊 Charts & Analytics
- Interactive pie charts for goal progress
- Bar charts for user distribution
- Real-time statistics dashboard
- CSV export for data analysis
- Role-based analytics filtering

## 📱 Mobile Responsive
- Sidebar collapses on mobile
- Touch-friendly buttons and forms
- Optimized layouts for small screens
- Responsive grid systems
- Mobile-first CSS approach

## 🎨 Theme & Styling
- Primary: #1976d2 (Blue)
- Light: #e3f2fd (Light Blue)
- Background: #f5f9ff (Very Light Blue)
- White: #ffffff
- Professional shadows and transitions
- Consistent spacing and typography

---

**Note**: For production deployment, update the JWT_SECRET in .env and use MongoDB Atlas for the database.
