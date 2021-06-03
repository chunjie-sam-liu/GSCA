import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { GsvascoreComponent } from './gsvascore.component';

describe('GsvascoreComponent', () => {
  let component: GsvascoreComponent;
  let fixture: ComponentFixture<GsvascoreComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ GsvascoreComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(GsvascoreComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
