import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import BottomNav from '../components/BottomNav';
import { supabase } from '../lib/supabaseClient';
import { geocodeAddress, type GeocodeResult } from '../lib/geocode';
import { getSession } from '../lib/session';
import { resizeImageToLimit } from '../lib/imageResize';

const MAX_PHOTOS = 10;

interface PhotoDraft {
  file: File;
  previewUrl: string;
}

export default function TravelRecordFormPage() {
  const navigate = useNavigate();

  const [title, setTitle] = useState('');
  const [region, setRegion] = useState('');
  const [address, setAddress] = useState('');
  const [geo, setGeo] = useState<GeocodeResult | null>(null);
  const [geocoding, setGeocoding] = useState(false);
  const [geoError, setGeoError] = useState<string | null>(null);
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [content, setContent] = useState('');
  const [photos, setPhotos] = useState<PhotoDraft[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleCheckAddress() {
    if (!address.trim()) return;
    setGeocoding(true);
    setGeoError(null);
    setGeo(null);
    const result = await geocodeAddress(address.trim());
    setGeocoding(false);
    if (!result) {
      setGeoError('주소를 찾지 못했습니다. 다르게 입력해보세요.');
      return;
    }
    setGeo(result);
  }

  async function handlePhotoSelect(files: FileList | null) {
    if (!files) return;
    const remaining = MAX_PHOTOS - photos.length;
    const selected = Array.from(files).slice(0, remaining);
    const resized = await Promise.all(selected.map((f) => resizeImageToLimit(f)));
    const next = resized.map((file) => ({ file, previewUrl: URL.createObjectURL(file) }));
    setPhotos((prev) => [...prev, ...next]);
  }

  function removePhoto(index: number) {
    setPhotos((prev) => {
      URL.revokeObjectURL(prev[index].previewUrl);
      return prev.filter((_, i) => i !== index);
    });
  }

  const formValid =
    title.trim().length > 0 &&
    region.trim().length > 0 &&
    geo !== null &&
    startDate.length > 0 &&
    endDate.length > 0 &&
    endDate >= startDate &&
    content.trim().length > 0;

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!formValid || !geo) return;

    const user = getSession();
    if (!user) {
      setError('로그인 정보가 없습니다. 다시 로그인해주세요.');
      return;
    }

    setSubmitting(true);
    setError(null);

    const { data: record, error: insertError } = await supabase
      .from('travel_records')
      .insert({
        user_id: user.id,
        title: title.trim(),
        region: region.trim(),
        address: address.trim(),
        country: geo.country,
        lat: geo.lat,
        lng: geo.lng,
        is_domestic: geo.isDomestic,
        start_date: startDate,
        end_date: endDate,
        content: content.trim(),
      })
      .select()
      .single();

    if (insertError || !record) {
      setSubmitting(false);
      setError('저장 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
      return;
    }

    for (let i = 0; i < photos.length; i++) {
      const { file } = photos[i];
      const ext = file.name.split('.').pop();
      const path = `${record.id}/${i}-${Date.now()}.${ext}`;
      const { error: uploadError } = await supabase.storage.from('travel-photos').upload(path, file);
      if (!uploadError) {
        await supabase.from('travel_record_photos').insert({
          travel_record_id: record.id,
          storage_path: path,
          sort_order: i,
        });
      }
    }

    setSubmitting(false);
    navigate('/travel');
  }

  return (
    <div className="app-frame">
      <header className="safe-top px-5 pt-4 pb-3 bg-white border-b border-gray-border">
        <h1 className="text-[20px] font-bold text-text-900">여행 기록 등록</h1>
      </header>

      <main className="flex-1 overflow-y-auto px-5 pt-4 pb-28">
        <form onSubmit={handleSubmit} className="flex flex-col gap-5" noValidate>
          <Field label="제목">
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="예: 제주도 가족 여행"
              className="w-full h-12 px-4 rounded-xl border text-[15px] text-text-900 placeholder:text-text-400"
              style={{ borderColor: '#E5E7EB' }}
            />
          </Field>

          <Field label="지역">
            <input
              value={region}
              onChange={(e) => setRegion(e.target.value)}
              placeholder="예: 제주 협재"
              className="w-full h-12 px-4 rounded-xl border text-[15px] text-text-900 placeholder:text-text-400"
              style={{ borderColor: '#E5E7EB' }}
            />
          </Field>

          <Field label="지역 주소">
            <div className="flex gap-2">
              <input
                value={address}
                onChange={(e) => {
                  setAddress(e.target.value);
                  setGeo(null);
                }}
                placeholder="예: 제주특별자치도 제주시 협재리"
                className="flex-1 h-12 px-4 rounded-xl border text-[15px] text-text-900 placeholder:text-text-400"
                style={{ borderColor: '#E5E7EB' }}
              />
              <button
                type="button"
                onClick={handleCheckAddress}
                disabled={!address.trim() || geocoding}
                className="shrink-0 h-12 px-4 rounded-xl text-[14px] font-semibold text-white disabled:opacity-40"
                style={{ background: '#111827' }}
              >
                {geocoding ? '확인 중' : '위치 확인'}
              </button>
            </div>
            {geoError && (
              <p className="text-[12px] mt-1.5 font-semibold" style={{ color: '#111827' }}>
                {geoError}
              </p>
            )}
            {geo && (
              <p className="text-[12px] mt-1.5 text-text-600">
                ✓ 위치 확인됨 — {geo.country ?? '알 수 없음'} ({geo.isDomestic ? '한국' : '해외'})
              </p>
            )}
          </Field>

          <Field label="여행 일자">
            <div className="flex items-center gap-2">
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="flex-1 h-12 px-3 rounded-xl border text-[14px] text-text-900"
                style={{ borderColor: '#E5E7EB' }}
              />
              <span className="text-text-400">~</span>
              <input
                type="date"
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                min={startDate || undefined}
                className="flex-1 h-12 px-3 rounded-xl border text-[14px] text-text-900"
                style={{ borderColor: '#E5E7EB' }}
              />
            </div>
          </Field>

          <Field label="여행 기록">
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder="여행에서 있었던 일을 기록해보세요"
              rows={6}
              className="w-full px-4 py-3 rounded-xl border text-[15px] text-text-900 placeholder:text-text-400 resize-none"
              style={{ borderColor: '#E5E7EB' }}
            />
          </Field>

          <Field label={`사진 첨부 (${photos.length}/${MAX_PHOTOS})`}>
            <div className="grid grid-cols-4 gap-2">
              {photos.map((p, i) => (
                <div key={p.previewUrl} className="relative aspect-square rounded-lg overflow-hidden border border-gray-border">
                  <img src={p.previewUrl} alt="" className="w-full h-full object-cover" />
                  <button
                    type="button"
                    onClick={() => removePhoto(i)}
                    aria-label="사진 삭제"
                    className="absolute top-1 right-1 w-5 h-5 rounded-full flex items-center justify-center text-white text-[12px]"
                    style={{ background: 'rgba(17,24,39,0.75)' }}
                  >
                    ×
                  </button>
                </div>
              ))}
              {photos.length < MAX_PHOTOS && (
                <label className="aspect-square rounded-lg border border-dashed flex items-center justify-center text-text-400 text-[22px] cursor-pointer" style={{ borderColor: '#E5E7EB' }}>
                  +
                  <input
                    type="file"
                    accept="image/*"
                    multiple
                    className="hidden"
                    onChange={(e) => handlePhotoSelect(e.target.files)}
                  />
                </label>
              )}
            </div>
          </Field>

          {error && (
            <p className="text-[13px] text-center font-semibold" style={{ color: '#111827' }}>
              {error}
            </p>
          )}

          <button
            type="submit"
            disabled={!formValid || submitting}
            className="w-full h-13 rounded-xl text-white font-medium text-[15px] disabled:opacity-40"
            style={{ height: 52, background: '#111827' }}
          >
            {submitting ? '저장 중...' : '여행 기록 저장'}
          </button>
        </form>
      </main>

      <BottomNav />
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <label className="block text-[13px] font-semibold text-text-600 mb-1.5">{label}</label>
      {children}
    </div>
  );
}
