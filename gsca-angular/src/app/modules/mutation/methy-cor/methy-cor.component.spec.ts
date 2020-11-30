import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { MethyCorComponent } from './methy-cor.component';

describe('MethyCorComponent', () => {
  let component: MethyCorComponent;
  let fixture: ComponentFixture<MethyCorComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ MethyCorComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(MethyCorComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
